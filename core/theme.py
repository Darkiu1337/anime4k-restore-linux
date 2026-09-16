import os
import subprocess

DARK = {
    "bg": "#1a1b26",
    "panel": "#24283b",
    "panelAlt": "#1f2335",
    "field": "#16161e",
    "text": "#c0caf5",
    "subtext": "#9aa0b8",
    "faint": "#565f89",
    "accent": "#7aa2f7",
    "accentText": "#1a1b26",
    "hover": "#2a2e46",
    "pressed": "#343a56",
    "border": "#343a56",
    "danger": "#f7768e",
    "ok": "#9ece6a",
    "buttonText": "#c0caf5",
}

LIGHT = {
    "bg": "#e1e2e7",
    "panel": "#d5d6db",
    "panelAlt": "#cbccd1",
    "field": "#f1f1f4",
    "text": "#343b58",
    "subtext": "#5a5f7a",
    "faint": "#9699b3",
    "accent": "#34548a",
    "accentText": "#ffffff",
    "hover": "#c5c6cc",
    "pressed": "#b4b5bd",
    "border": "#b4b5bd",
    "danger": "#8c4351",
    "ok": "#4c7a2b",
    "buttonText": "#343b58",
}

PALETTES = {"dark": DARK, "light": LIGHT}

OMARCHY_STATE = os.path.expanduser("~/.local/state/omarchy/current/theme.name")
OMARCHY_SCHEMES = os.path.expanduser("~/.local/share/color-schemes")


def _rgb(value, fallback):
    try:
        parts = [int(x) for x in str(value).split(",")[:3]]
        if len(parts) != 3:
            return fallback
        return tuple(max(0, min(255, p)) for p in parts)
    except (ValueError, TypeError):
        return fallback


def _hex(rgb):
    return "#%02x%02x%02x" % rgb


def _blend(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _parse_kde_colors(path):
    """KDE .colors (INI) -> {section: {key: value}}. [] when unreadable."""
    out = {}
    section = None
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("[") and line.endswith("]"):
                    section = line[1:-1]
                    out.setdefault(section, {})
                elif section and "=" in line:
                    k, _, v = line.partition("=")
                    out[section][k.strip()] = v.strip()
    except OSError:
        return {}
    return out


def omarchy_name():
    try:
        with open(OMARCHY_STATE, encoding="utf-8") as f:
            name = f.read().strip()
        return name or None
    except OSError:
        return None


def omarchy_palette():
    """Palette derived from the active Omarchy KDE color scheme, or None."""
    name = omarchy_name()
    if not name:
        return None
    path = os.path.join(OMARCHY_SCHEMES, f"omarchy-{name}.colors")
    if not os.path.isfile(path):
        return None
    c = _parse_kde_colors(path)
    window = c.get("Colors:Window", {})
    button = c.get("Colors:Button", {})
    view = c.get("Colors:View", {})
    sel = c.get("Colors:Selection", {})
    if not window:
        return None

    bg = _rgb(window.get("BackgroundNormal"), (18, 18, 18))
    text = _rgb(window.get("ForegroundNormal"), (190, 190, 190))
    panel = _rgb(button.get("BackgroundNormal"), bg)
    panel_alt = _rgb(button.get("BackgroundAlternate"), _blend(bg, text, 0.08))
    field = _rgb(view.get("BackgroundNormal"), _blend(bg, text, 0.06))
    accent = _rgb(window.get("DecorationFocus") or window.get("ForegroundActive"),
                  text)
    subtext = _blend(bg, text, 0.55)
    faint = _rgb(window.get("ForegroundInactive"), _blend(bg, text, 0.35))
    label = "light" if sum(bg) > 384 else "dark"
    return label, {
        "bg": _hex(bg),
        "panel": _hex(panel),
        "panelAlt": _hex(panel_alt),
        "field": _hex(field),
        "text": _hex(text),
        "subtext": _hex(subtext),
        "faint": _hex(faint),
        "accent": _hex(accent),
        "accentText": _hex(_rgb(sel.get("ForegroundNormal"), (255, 255, 255))),
        "hover": _hex(_blend(panel, text, 0.12)),
        "pressed": _hex(_blend(panel, text, 0.20)),
        "border": _hex(_blend(panel, text, 0.16)),
        "danger": _hex(_rgb(window.get("ForegroundNegative"), (211, 95, 95))),
        "ok": _hex(_rgb(window.get("ForegroundPositive"), (255, 193, 7))),
        "buttonText": _hex(text),
    }


def portal_scheme():
    try:
        out = subprocess.run(
            ["gdbus", "call", "--session",
             "--dest", "org.freedesktop.portal.Desktop",
             "--object-path", "/org/freedesktop/portal/desktop",
             "--method", "org.freedesktop.portal.Settings.Read",
             "org.freedesktop.appearance", "color-scheme"],
            capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    if "uint32 1" in out:
        return "dark"
    if "uint32 2" in out:
        return "light"
    return None


def gsettings_scheme():
    try:
        out = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"],
            capture_output=True, text=True, timeout=5).stdout.lower()
    except (OSError, subprocess.SubprocessError):
        return None
    if "light" in out:
        return "light"
    if "dark" in out:
        return "dark"
    return None


def resolve(override=""):
    """(label, palette, source). override: System | Omarchy | dark | light.
    System/Omarchy prefer the active Omarchy scheme, then portal/gsettings,
    then builtin dark. Never raises."""
    override = (override or "System").strip()
    if override == "dark":
        return "dark", dict(DARK), "builtin"
    if override == "light":
        return "light", dict(LIGHT), "builtin"
    try:
        got = omarchy_palette()
        if got:
            return got[0], got[1], "omarchy"
        if override == "Omarchy":
            return "dark", dict(DARK), "builtin"
        detected = portal_scheme() or gsettings_scheme() or "dark"
    except Exception:
        detected = "dark"
    return detected, dict(PALETTES.get(detected, DARK)), "system"


def palette_for(override=""):
    label, pal, _ = resolve(override)
    return label, pal


def scheme(override=""):
    return resolve(override)[0]
