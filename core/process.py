import json
import os
import signal
import subprocess
import time

from . import paths, store


def stray_token(game):
    """pgrep token identifying this game's processes (bracketed by caller)."""
    if game.get("runner") == "rpgmaker":
        return "nw --ozone-platform"
    return os.path.basename(game.get("path", ""))


def find_strays(token):
    """PIDs matching token, self-excluding via bracket pattern. Never raises."""
    if not token:
        return []
    pat = f"[{token[0]}]{token[1:]}"
    try:
        out = subprocess.run(["pgrep", "-f", pat], capture_output=True,
                             text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    me = os.getpid()
    return [int(p) for p in out.split() if p.isdigit() and int(p) != me]


def kill_strays(token):
    """TERM, grace wait, then KILL leftovers. Returns True if anything was found."""
    pids = find_strays(token)
    if not pids:
        return False
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    time.sleep(2)
    for pid in pids:
        try:
            os.kill(pid, 0)
        except OSError:
            continue
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass
    return True


def translate_bridge_ok():
    """True when something answers :6677 with a real ws handshake.
    Never probe with bare TCP: the stock bridge panics on non-handshakes
    (see docs/translate.md)."""
    try:
        import websocket
        ws = websocket.create_connection("ws://127.0.0.1:6677", timeout=3)
        ws.close()
        return True
    except Exception:
        return False


def textbox_pids():
    """PIDs of a running textbox backend (workers = owns the translator)."""
    try:
        out = subprocess.run(["pgrep", "-f", r"[t]extbox\.py --start-workers"],
                             capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return [p for p in (x.strip() for x in out.splitlines()) if p]


def translate_cdp_profile():
    """(full path, basename) of the isolated translator-browser profile.
    Never the real browser profile — automation always gets its own dir."""
    try:
        with open(os.path.join(paths.TRANSLATE_DIR, "config.json"), encoding="utf-8") as f:
            prof = (json.load(f) or {}).get("brave_profile", "")
    except (OSError, ValueError):
        prof = ""
    prof = os.path.expanduser(os.path.expandvars(
        prof or "~/.cache/vn-translate/brave-cdp-profile"))
    base = os.path.basename(prof.rstrip("/")) or "brave-cdp-profile"
    return prof, base


def textbox_brave_pattern():
    """pkill -f pattern matching ONLY translator browsers: the isolated
    profile marker in the cmdline, whatever the binary."""
    _, base = translate_cdp_profile()
    esc = "".join(("\\" + ch) if ch in ".+*?()[]{}^$|\\" else ch for ch in base)
    if esc and esc[0].isalnum():
        return f"user-data-dir=[^ ]*[{esc[0]}]{esc[1:]}"
    return f"user-data-dir=[^ ]*{esc}"


def kill_textbox_group(proc, sig):
    """Signal the textbox process group (backend + translator browser it
    spawned). Returns True if a live group was signaled."""
    try:
        if proc is None or proc.poll() is not None:
            return False
        os.killpg(os.getpgid(proc.pid), sig)
        return True
    except (OSError, ProcessLookupError):
        return False


def kill_orphan_browsers():
    """Orphaned translator browsers (backend died without cleanup): only the
    isolated CDP profile ever matches — real browsers are safe. Returns True
    when a kill landed."""
    try:
        r = subprocess.run(["pkill", "-f", textbox_brave_pattern()],
                           capture_output=True, timeout=10)
        return r.returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def translate_wedge_pids(game_base=""):
    """PIDs of wedged translate containers: umu-run ... hook .vbs older than
    ~3 min while no game/hooker process lives and the bridge is down.
    That's the wineserver -w stall signature (see docs/translate.md)."""
    try:
        out = subprocess.run(["ps", "-eo", "pid,etimes,args"], capture_output=True,
                             text=True, timeout=10).stdout.splitlines()
    except (OSError, subprocess.SubprocessError):
        return []
    game_alive = False
    old_launchers = []
    gb = os.path.basename(game_base or "").lower()
    for line in out:
        parts = line.split(None, 2)
        if len(parts) != 3:
            continue
        pid, etime, args = parts
        if not pid.isdigit():
            continue
        if ("umu-run" in args and "hook" in args and ".vbs" in args
                and "ps -eo" not in args):
            try:
                if int(etime) > 180:
                    old_launchers.append(int(pid))
            except ValueError:
                pass
        low = args.lower()
        if (("textractor.exe" in low or (gb and gb in low))
                and "umu-run" not in low and "ps -eo" not in args):
            game_alive = True
    if old_launchers and not game_alive and not translate_bridge_ok():
        return old_launchers
    return []


def stop_session(game_path, timeout=90):
    """vn-launch.sh --stop-exe: ends game hooks, textbox backend and its
    browser (a backend left running keeps translating and re-shows)."""
    try:
        subprocess.run([os.path.join(paths.TRANSLATE_DIR, "vn-launch.sh"),
                        "--stop-exe", game_path], timeout=timeout,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (OSError, subprocess.SubprocessError):
        pass


def spawn_textbox(gid=None):
    """Start the textbox backend (single instance, stderr kept). Returns
    (proc, message). proc is None on failure/refusal."""
    argv = [os.path.join(paths.TRANSLATE_DIR, paths.TEXTBOX_PROG), "--start-workers"]
    try:
        game = store.load_games().get(gid or "")
        thread = ((game or {}).get("translate") or {}).get("thread", "").strip()
        if thread:
            argv += ["--thread", thread]
    except Exception:
        pass
    if textbox_pids():
        return None, "textbox: already running (one instance only)."
    try:
        logdir = os.path.expanduser("~/.cache/anime4k")
        os.makedirs(logdir, exist_ok=True)
        logf = open(os.path.join(logdir, "textbox.log"), "ab", buffering=0)
    except OSError:
        logf = subprocess.DEVNULL
    try:
        proc = subprocess.Popen(argv, stdout=logf, stderr=logf,
                                stdin=subprocess.DEVNULL, start_new_session=True)
        return proc, "textbox: started (stderr -> ~/.cache/anime4k/textbox.log)"
    except (OSError, subprocess.SubprocessError) as e:
        return None, f"textbox: could not open ({e})"
