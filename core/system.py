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
