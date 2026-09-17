#!/bin/bash
# vn-launch.sh — universal single-container VN launcher (replaces mlove-hook.sh).
# One umu-run -> wscript -> per-game launch.vbs (hooker + game, one wineserver).
# Filter (Anime4K Restore via vkBasalt) is applied in-process when --filter is
# given, by sourcing anime4k-lib.sh — the same mechanism as proton-anime4k.sh,
# so filter + translation compose in one launch.
# Usage: vn-launch.sh --game ID [--setup] [--show-hooker] [--filter VARIANT|off] [--dry-run]
#                      | --exe PATH --gameid ID [--lang LOCALE] [--hook-code CODE] [--setup] [--show-hooker] [--filter ...] [--dry-run]
#                      | --stop ID | --stop-exe PATH | --status | --list
#   --exe bypasses the games registry (used by anime4k GUI/TUI: games.json is
#     the single registry there). --gameid/--lang default sanely with --exe.
#     --hook-code seeds Textractor's SavedHooks so the recorded hook
#     auto-inserts at attach (no manual Add-hook).
#   --setup  Setup mode: opens the in-app Text Hooker picker. Textractor stays
#            HIDDEN; --show-hooker reveals Textractor's window (debug).
#            Default (play mode): Textractor HIDDEN (style 0), game normal.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
REG="$HERE/translate.json"
# Shared core (config, variants, vkBasalt, WoW64). Sourced early so --no-wow64
# applies even with --filter off; docs/limits.md.
AK_LIB="$(dirname "$HERE")/scripts/anime4k-lib.sh"
if [ -f "$AK_LIB" ]; then
  # shellcheck disable=SC1090
  source "$AK_LIB"
fi
GAME=""; SETUP=0; SHOW_HOOKER=0; CMD="launch"; FILTER="off"; DRYRUN=0
EXE_FLAG=""; GAMEID_FLAG=""; LANG_FLAG=""; HOOKCODE_FLAG=""; WOW64_FLAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --game) GAME="$2"; shift 2 ;;
    --exe) EXE_FLAG="$2"; shift 2 ;;
    --gameid) GAMEID_FLAG="$2"; shift 2 ;;
    --lang) LANG_FLAG="$2"; shift 2 ;;
    --hook-code) HOOKCODE_FLAG="$2"; shift 2 ;;
    --setup) SETUP=1; shift ;;
    --show-hooker) SHOW_HOOKER=1; shift ;;
    --filter) FILTER="$2"; shift 2 ;;
    --dry-run) DRYRUN=1; shift ;;
    --stop) GAME="$2"; CMD="stop"; shift 2 ;;
    --stop-exe) EXE_FLAG="$2"; CMD="stop-exe"; shift 2 ;;
    --status) CMD="status"; shift ;;
    --list) CMD="list"; shift ;;
    --prefix) PREFIX_OVERRIDE="$2"; shift 2 ;;
    --wow64) WOW64_FLAG=1; shift ;;
    --no-wow64) WOW64_FLAG=0; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

jget() { python3 -c "import json; print(json.load(open('$REG'))$1)" 2>/dev/null; }

need_reg() { # need_reg <cmd>: the games registry only ships as a sample
  if [ ! -f "$REG" ]; then
    echo "$1: no games registry at $REG" >&2
    echo "hint: cp $HERE/translate.json.sample $REG, then edit exe paths (or launch via --exe/--gameid from the GUI/TUI)" >&2
    exit 1
  fi
}

if [ "$CMD" = "list" ]; then
  need_reg "list"
  python3 -c "import json; [print(g['id']+' — '+g.get('name',g['id'])) for g in json.load(open('$REG'))['games']]"
  exit 0
fi

PREFIX="$(python3 -c "import json; print(json.load(open('$HOME/.config/anime4k/config.json')).get('prefix', ''))" 2>/dev/null || true)"
[ -n "$PREFIX" ] || PREFIX="$HOME/.local/share/anime4k/prefixes/default"
[ -n "${PREFIX_OVERRIDE:-}" ] && PREFIX="$PREFIX_OVERRIDE"
PROTON="$(python3 -c "import json; print(json.load(open('$HOME/.config/anime4k/config.json')).get('proton', ''))" 2>/dev/null || true)"
if [ -n "$WOW64_FLAG" ]; then
  WOW64="$WOW64_FLAG"
elif command -v ak_config_get >/dev/null 2>&1; then
  WOW64="$(ak_config_get wow64 1)"
else
  WOW64="1"
fi
# A selected Proton without new WoW64 support falls back to umu-managed.
if [ "$WOW64" = "1" ] && [ -n "$PROTON" ] \
   && command -v ak_proton_wow64_capable >/dev/null 2>&1 \
   && ! ak_proton_wow64_capable "$PROTON"; then
  echo "warning: '$PROTON' has no new WoW64 support — falling back to umu-managed UMU-Proton" >&2
  PROTON=""
  unset PROTONPATH
fi
UMU="$(command -v umu-run)" || { echo "umu-run not found" >&2; exit 1; }
TRX="$PREFIX/drive_c/Textractor/x86/Textractor.exe"
[ -f "$TRX" ] || "$HERE/install-textractor.sh" --prefix "$PREFIX"

if [ "$CMD" = "status" ]; then
  "$HERE/watch-bridge.sh" --once
  exit $?
fi

[ -n "$GAME" ] || [ -n "$EXE_FLAG" ] || { echo "need --game ID or --exe PATH (see --list)" >&2; exit 1; }
if [ -n "$EXE_FLAG" ]; then
  EXE="$EXE_FLAG"
  GAMEID="${GAMEID_FLAG:-game}"
  LANG_SET="${LANG_FLAG:-ja_JP.UTF-8}"
  [ -n "$GAME" ] || GAME="$GAMEID"
else
  need_reg "--game"
  EXE="$(python3 -c "import json; print([g for g in json.load(open('$REG'))['games'] if g['id']=='$GAME'][0]['exe'])")"
  GAMEID="$(python3 -c "import json; print([g for g in json.load(open('$REG'))['games'] if g['id']=='$GAME'][0].get('gameid','$GAME'))")"
  LANG_SET="$(python3 -c "import json; print([g for g in json.load(open('$REG'))['games'] if g['id']=='$GAME'][0].get('lang','ja_JP.UTF-8'))")"
  [ -n "$HOOKCODE_FLAG" ] || HOOKCODE_FLAG="$(python3 -c "import json; print([g for g in json.load(open('$REG'))['games'] if g['id']=='$GAME'][0].get('hook_code',''))")"
fi
BASE="$(basename "$EXE")"
BASE_NOEXT="${BASE%.exe}"; BASE_NOEXT="${BASE_NOEXT%.EXE}"

stop_session() { # stop_session <label>: kill game exes, wscript, stale wineserver
  # Match the Wine-side argv form (X:\dir\game.exe); a backslash-anchored
  # pattern can never match a unix path, so it cannot kill our own shell.
  local label="$1"
  local esc="${BASE//./\\.}" pat1
  pat1="[\\\\]${esc:1}"
  pkill -f "$pat1" 2>/dev/null || true
  sleep 3
  pkill -9 -f "$pat1" 2>/dev/null || true
  pkill -f "[w]script.exe C" 2>/dev/null || true
  sleep 5
  if pgrep -f "$pat1" >/dev/null 2>&1; then echo "stop: processes remain"; exit 1; fi
  # Drop lingering wineserver or the next launch wedges (docs/translate.md).
  _P="$HOME/.local/share/Steam/compatibilitytools.d/Proton-CachyOS Latest"
  if [ -x "$_P/files/bin/wineserver" ]; then
    WINEPREFIX="$PREFIX" "$_P/files/bin/wineserver" -k 2>/dev/null || true
  fi
  unset _P
  echo "stop: $label session ended"
}

if [ "$CMD" = "stop" ] || [ "$CMD" = "stop-exe" ]; then
  # Kill this game's processes only (bracketed patterns never match self).
  stop_session "$GAME"
  exit 0
fi

# --- launch ---
[ -f "$EXE" ] || { echo "game not found: $EXE" >&2; exit 1; }
mkdir -p "$PREFIX/drive_c/hook"
seed_saved_hooks() { # <wine-exe-path> <hook-code>: Textractor auto-attach
  # Seeded lines never clobber a richer user-saved hook (docs/translate.md).
  local vexe="$1" code="$2" tdir="$PREFIX/drive_c/Textractor/x86"
  [ -d "$tdir" ] || return 0
  python3 - "$tdir" "$vexe" "$code" <<'PYEOF'
import os, sys
tdir, vexe, code = sys.argv[1], sys.argv[2], sys.argv[3]
def raw(name):
    try:
        with open(os.path.join(tdir, name), encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""
def load(name):
    # CRLF->LF: upstream exact-matches these lines (docs/translate.md).
    return [l.strip() for l in raw(name).splitlines() if l.strip()]
hooks, games = load("SavedHooks.txt"), load("SavedGames.txt")
have_rich = any((l.split(" , ")[0] == vexe and " , " in l) for l in hooks)
if not have_rich:
    hooks = [l for l in hooks if l.split(" , ")[0] != vexe]
    hooks.append(vexe + (" , " + code if code else ""))
    with open(os.path.join(tdir, "SavedHooks.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(hooks) + "\n")
    print("seeded SavedHooks.txt ({})".format("hook " + code if code else "attach only"))
else:
    print("SavedHooks.txt keeps user-saved hooks")
if vexe not in games:
    games.append(vexe)
new_games = "\n".join(games) + "\n"
if new_games != raw("SavedGames.txt"):
    with open(os.path.join(tdir, "SavedGames.txt"), "w", encoding="utf-8") as f:
        f.write(new_games)
PYEOF
}
# Hooker hidden by default (play AND setup); --show-hooker reveals it (debug).
if [ "$SETUP" = "1" ] && [ "$SHOW_HOOKER" = "1" ]; then
  HSTYLE=1; MODE="setup (Textractor visible)"
elif [ "$SETUP" = "1" ]; then
  HSTYLE=0; MODE="setup (Textractor hidden, pick in-app)"
else
  HSTYLE=0; MODE="play (Textractor hidden)"
fi
GDIR="$(dirname "$EXE")"
to_winpath() { python3 -c "
import sys
p = sys.argv[1]
pfx = sys.argv[2]
print('Z:' + p.replace('/', chr(92)) if not p.startswith(pfx + '/drive_c') else 'C:' + p[len(pfx + '/drive_c'):].replace('/', chr(92)))
" "$1" "$PREFIX"; }
VGAME="$(to_winpath "$EXE")"
VGDIR="$(to_winpath "$GDIR")"
GBASE="${VGAME##*\\}"
seed_saved_hooks "$VGAME" "$HOOKCODE_FLAG"
python3 - "$HERE/launch.vbs.template" "$PREFIX/drive_c/hook/$GAME.vbs" <<EOF
import sys
t = open(sys.argv[1], 'rb').read().decode('utf-8')
t = t.replace('@HOOKER_DIR@', r'C:\Textractor\x86')
t = t.replace('@HOOKER_EXE@', r'C:\Textractor\x86\Textractor.exe')
t = t.replace('@HOOKER_STYLE@', '$HSTYLE')
t = t.replace('@GAME_BASE@', r'$GBASE')
t = t.replace('@GAME_DIR@', r'$VGDIR')
t = t.replace('@GAME_EXE@', r'$VGAME')
open(sys.argv[2], 'wb').write(t.replace('\n', '\r\n').encode('ascii'))
print('rendered $GAME.vbs (hooker style $HSTYLE)')
EOF
export WINEPREFIX="$PREFIX"
[ -n "$PROTON" ] && export PROTONPATH="$PROTON"
export GAMEID
export LANG="$LANG_SET" HOST_LC_ALL="$LANG_SET"
if command -v ak_wow64_env >/dev/null 2>&1; then ak_wow64_env "$PREFIX" "$WOW64"; fi
# Filter: same vkBasalt mechanism as proton-anime4k.sh (variant conf + layer env).
if [ "$FILTER" != "off" ]; then
  if command -v ak_vkbasalt_env >/dev/null 2>&1; then
    FILTER="$(ak_variant "$FILTER")"
    ak_vkbasalt_env "$FILTER"
    echo "filter=Anime4K-Restore-$FILTER conf=$VKBASALT_CONFIG_FILE"
  else
    echo "warning: anime4k-lib.sh not found at $AK_LIB; launching unfiltered" >&2
    FILTER="off"
  fi
fi
if [ "$DRYRUN" = "1" ]; then
  echo "WINEPREFIX=$PREFIX PROTONPATH=${PROTON:-umu-managed} GAMEID=$GAMEID"
  echo "game=$EXE lang=$LANG_SET filter=$FILTER wow64=$([ "$WOW64" = "1" ] && echo on || echo off) dxvk=${DXVK_FILTER_DEVICE_NAME:-loader-default}"
  echo "vkbasalt=${VKBASALT_CONFIG_FILE:-off} layer=${VK_INSTANCE_LAYERS:-off}"
  printf 'umu-run %q %q\n' \
    "$PREFIX/drive_c/windows/system32/wscript.exe" "C:\\hook\\$GAME.vbs"
  exit 0
fi
echo "launching $GAME [$MODE] (end session with Ctrl-C)…"
set -x
# exec so the GUI's Stop terminates the container (no orphaned wineserver).
exec "$UMU" "$PREFIX/drive_c/windows/system32/wscript.exe" "C:\\hook\\$GAME.vbs"
