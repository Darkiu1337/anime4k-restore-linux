#!/bin/bash
# watch-bridge.sh — session watchdog (NOTIFIER, not auto-healer).
# Why not auto-heal: Textractor can only join the game's Wine session at
# launch time (dual umu-run serializes); restarting the hooker means restarting
# the game, which would lose unsaved progress. So this script watches and
# notifies; the human decides.
# Usage: watch-bridge.sh [--once]
#   --once  single check, prints status, exits 0 (up) / 1 (bridge down, game up) / 2 (all down)
set -e
GAME_PAT="[m]love.exe"
HOOK_PAT="[T]extractor.exe"
PORT=6677
DOWN_SINCE=0

status() {
  if pgrep -f "$GAME_PAT" >/dev/null; then
    if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then echo up; else echo hooker-down; fi
  else
    echo session-over
  fi
}

if [ "${1:-}" = "--once" ]; then
  case "$(status)" in
    up) echo "session healthy (game + bridge)"; exit 0 ;;
    hooker-down) echo "BRIDGE DOWN, game alive"; exit 1 ;;
    *) echo "session over"; exit 2 ;;
  esac
fi

# Singleton: a second watcher just exits.
if pgrep -f "[w]atch-bridge.sh" | grep -qv "^$$"; then
  echo "watcher already running"
  exit 0
fi

notify() { notify-send "vn-translate" "$1" 2>/dev/null || echo "WATCH: $1" >&2; }
notify "watching session (game + :$PORT bridge)"
while true; do
  case "$(status)" in
    up) DOWN_SINCE=0 ;;
    hooker-down)
      if [ "$DOWN_SINCE" = "0" ]; then DOWN_SINCE="$(date +%s)"; fi
      if [ "$(( $(date +%s) - DOWN_SINCE ))" -ge 60 ]; then
        notify "Textractor bridge down >60s, game still running. Close game, then: vn-launch.sh --game <id>"
        DOWN_SINCE="$(date +%s)"; sleep 300; continue
      fi
      ;;
    session-over) notify "session over, watcher exiting"; exit 0 ;;
  esac
  sleep 10
done
