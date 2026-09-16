import os

from . import paths


def gpu_icd(name):
    if name.startswith("auto"):
        return "auto"
    if "NVIDIA" in name:
        return "nvidia"
    if any(k in name for k in ("AMD", "ATI", "Radeon")):
        return "amd"
    return "auto"


def build_command(game):
    """Argv for a library entry (mirrors the bash runners)."""
    runner = game["runner"]
    variant = game.get("variant", "L")
    fps = game.get("fps", "60")
    hud = game.get("hud", "0")
    gpu = game.get("gpu", "auto (discrete GPU preferred)")
    pmode = game.get("prefix_mode", "shared")
    lang = game.get("lang", "")
    path = game["path"]
    if runner == "proton":
        argv = [os.path.join(paths.SCRIPTS_DIR, "proton-anime4k.sh"),
                "--variant", variant, "--fps", fps,
                "--prefix-mode", pmode if pmode in ("shared", "game") else "shared"]
        if hud == "1":
            argv.append("--hud")
        if lang:
            argv += ["--lang", lang]
        if not gpu.startswith("auto"):
            argv += ["--dxvk-device", gpu]
        argv.append(path)
    elif runner == "rpgmaker":
        argv = [os.path.join(paths.SCRIPTS_DIR, "rpgmaker-anime4k.sh"),
                "--variant", variant, "--gpu", gpu_icd(gpu),
                "--fps", fps]
        if hud == "1":
            argv.append("--hud")
        argv += ["--gamepath", path]
    else:
        argv = [os.path.join(paths.SCRIPTS_DIR, "native-anime4k.sh"),
                "--variant", variant, "--gpu", gpu_icd(gpu),
                "--fps", fps]
        if hud == "1":
            argv.append("--hud")
        if lang:
            argv += ["--lang", lang]
        argv.append(path)
    return argv


def build_translate_command(game, gid, setup=False):
    """Argv for a translation session (filter + DeepL in one launch).
    setup=True shows the Textractor window for first-time thread picking."""
    argv = [os.path.join(paths.TRANSLATE_DIR, "vn-launch.sh"),
            "--exe", game["path"], "--gameid", gid,
            "--filter", game.get("variant", "L")]
    if game.get("lang"):
        argv += ["--lang", game["lang"]]
    hook = (game.get("translate") or {}).get("hook_code", "").strip()
    if hook:
        argv += ["--hook-code", hook]
    if setup:
        argv += ["--setup"]
    return argv
