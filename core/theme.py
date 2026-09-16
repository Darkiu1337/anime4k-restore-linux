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


def scheme(override=""):
    """Effective scheme: explicit setting wins, then portal, then gsettings,
    then dark (Omarchy default). Never raises."""
    if override in ("dark", "light"):
        return override
    if override in ("System", "", None):
        pass
    try:
        return portal_scheme() or gsettings_scheme() or "dark"
    except Exception:
        return "dark"
