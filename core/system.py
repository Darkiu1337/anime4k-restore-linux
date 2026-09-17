import os
import re
import subprocess

from . import paths


def list_variants():
    """Variant names from the shader dir (auto-discovers future additions)."""
    found = []
    try:
        for fn in sorted(os.listdir(paths.SHADERS_DIR)):
            m = re.fullmatch(r"Anime4K_Restore_(.+)\.fx", fn)
            if m:
                found.append(m.group(1))
    except OSError:
        pass
    order = ["L", "M", "S", "Soft_S", "Soft_L"]
    return [v for v in order if v in found] + [v for v in found if v not in order]


def list_gpus():
    """Display names from the Vulkan loader; first entry is auto (= discrete
    GPU when detectable)."""
    names = ["auto (discrete GPU preferred)"]
    try:
        out = subprocess.run(["vulkaninfo", "--summary"], capture_output=True,
                             text=True, timeout=15).stdout
        seen = set()
        for line in out.splitlines():
            m = re.search(r"deviceName\s*=\s*(.+)", line)
            if m:
                name = m.group(1).strip()
                if name and name not in seen:
                    seen.add(name)
                    names.append(name)
    except (OSError, subprocess.SubprocessError):
        pass
    return names


# Proton discovery for the launcher's Proton dropdown. Only Proton-type
# builds (an executable `proton`/`proton.sh`) are listed; Wine runners are not
# selectable through the umu/PROTONPATH runner. `value` is an absolute path
# (umu accepts a path), "" means the umu-managed UMU-Proton.
PROTON_DIRS = (
    "~/.local/share/Steam/compatibilitytools.d",
    "~/.steam/steam/compatibilitytools.d",
    "~/.steam/root/compatibilitytools.d",
    "~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d",
    "/usr/share/steam/compatibilitytools.d",
    "/usr/local/share/steam/compatibilitytools.d",
)


def proton_wow64_capable(path):
    """True when a Proton dir can run 32-bit PE through new WoW64.
    A dir without a readable `proton` script is assumed capable (latest)."""
    if not os.path.isdir(path):
        return False
    if os.path.isfile(os.path.join(path, "files", "bin-wow64", "wine")):
        return True
    try:
        with open(os.path.join(path, "proton"), encoding="utf-8",
                  errors="replace") as f:
            if "PROTON_USE_WOW64" in f.read():
                return True
    except OSError:
        pass
    # A 64-bit-only build (no wine64 loader) always runs new WoW64.
    return (os.path.isfile(os.path.join(path, "files", "bin", "wine"))
            and not os.path.exists(os.path.join(path, "files", "bin", "wine64")))


def list_protons():
    """Pinned umu-managed entry first, then one per detected Proton build.
    Each entry: {label, value, wow64}."""
    out = [{"label": "umu-managed (UMU-Proton — always works)",
            "value": "", "wow64": True}]
    seen = set()
    found = []
    for root in PROTON_DIRS:
        root = os.path.expanduser(root)
        try:
            names = sorted(os.listdir(root))
        except OSError:
            continue
        for name in names:
            d = os.path.join(root, name)
            real = os.path.realpath(d)
            if real in seen or not os.path.isdir(d):
                continue
            proton = os.path.join(d, "proton")
            if not (os.path.isfile(proton) and os.access(proton, os.X_OK)):
                continue
            seen.add(real)
            found.append({"label": name, "value": d,
                          "wow64": proton_wow64_capable(d)})
    found.sort(key=lambda e: e["label"].lower())
    out.extend(found)
    return out


def detect(path):
    """Engine detection; wraps the proven bash implementation in
    scripts/anime4k-lib.sh. Returns (engine, runner, confidence, root, detail)
    or None when detection fails to run/returns garbage."""
    lib = os.path.join(paths.SCRIPTS_DIR, "anime4k-lib.sh")
    try:
        out = subprocess.run(
            ["bash", "-c", f'source "{lib}" && ak_detect_engine "$0"', path],
            capture_output=True, text=True, timeout=30).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None
    parts = out.split("|", 4)
    if len(parts) != 5:
        return None
    return tuple(parts)
