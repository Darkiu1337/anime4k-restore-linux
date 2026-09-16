import json
import os
import shutil
import subprocess

from . import paths

ICON_CACHE = paths.ICON_CACHE


def _manifest_icon(game_dir):
    for mf in (os.path.join(game_dir, "package.json"),
               os.path.join(game_dir, "www", "package.json")):
        try:
            with open(mf) as f:
                data = json.load(f)
            icon = data.get("window", {}).get("icon") or data.get("icon")
        except (OSError, ValueError):
            continue
        if not icon or not isinstance(icon, str):
            continue
        for cand in (os.path.join(game_dir, icon),
                     os.path.join(game_dir, "www", os.path.basename(icon))):
            if os.path.isfile(cand):
                return cand
    return None


def _exe_of(game_dir):
    try:
        for fn in sorted(os.listdir(game_dir)):
            if fn.lower().endswith(".exe"):
                return os.path.join(game_dir, fn)
    except OSError:
        pass
    return None


def resolve_icon(runner, path, gid):
    """Usable image path for the game (cached), or None for fallback.
    Sources: exe-embedded icon (icoextract) for proton titles; manifest art,
    then sibling exe, for rpgmaker/native titles. Cached icons survive
    unplugged drives (see docs/limits.md)."""
    os.makedirs(ICON_CACHE, exist_ok=True)
    for ext in (".png", ".ico"):
        hit = os.path.join(ICON_CACHE, gid + ext)
        if os.path.isfile(hit):
            return hit
    src = None
    if runner == "proton" and path.lower().endswith(".exe"):
        src = ("exe", path)
    elif runner in ("rpgmaker", "native"):
        base = path if os.path.isdir(path) else os.path.dirname(path)
        for cand in (_manifest_icon(base),
                     os.path.join(base, "icon.png"),
                     os.path.join(base, "icon.ico"),
                     os.path.join(base, "game", "icon.png")):
            if cand and os.path.isfile(cand):
                src = ("img", cand)
                break
        if src is None:
            exe = _exe_of(base)
            if exe:
                src = ("exe", exe)
    if src is None:
        return None
    kind, spath = src
    if kind == "img":
        dst = os.path.join(ICON_CACHE, gid + os.path.splitext(spath)[1].lower())
        try:
            shutil.copyfile(spath, dst)
            return dst
        except OSError:
            return spath
    if shutil.which("icoextract") is None:
        return None
    dst = os.path.join(ICON_CACHE, gid + ".ico")
    try:
        subprocess.run(["icoextract", spath, dst], timeout=30,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=True)
        return dst if os.path.isfile(dst) else None
    except (OSError, subprocess.SubprocessError):
        return None
