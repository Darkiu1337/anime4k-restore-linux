#!/bin/bash
# install-textractor.sh — install full Textractor x86 bundle (+ websocket bridge)
# into a Wine prefix. The FULL directory matters: Textractor.exe needs its
# bundled Qt5 runtime (Qt5*.dll, platforms/, styles/...) to open any window.
# Usage: install-textractor.sh [--prefix DIR] [--bridge stock|fixed] [--vendor-dir DIR]
#   --bridge fixed installs the hardened fork (no host panics, non-blocking
#     send, drain-all; see bridge-fork.patch). Default: stock 0.2.0.
#   Binaries are NEVER committed: run fetch-vendor.sh first (or set VENDOR_DIR).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX=""
BRIDGE="stock"
VDIR="${VENDOR_DIR:-$HERE/vendor}"
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --bridge) BRIDGE="$2"; shift 2 ;;
    --vendor-dir) VDIR="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
if [ -z "$PREFIX" ]; then
  PREFIX="$(python3 -c "import json; print(json.load(open('$HOME/.config/anime4k/config.json')).get('prefix', ''))" 2>/dev/null || true)"
  [ -n "$PREFIX" ] || PREFIX="$HOME/.local/share/anime4k/prefixes/default"
fi
SRC="$VDIR/textractor-full/x86"
[ -d "$SRC" ] || { echo "missing $SRC (run fetch-vendor.sh first)" >&2; exit 1; }
DST="$PREFIX/drive_c/Textractor/x86"
mkdir -p "$DST"
cp -rn "$SRC/." "$DST/"
cp -f "$SRC/Textractor.exe" "$SRC/TextractorCLI.exe" "$SRC/texthook.dll" "$DST/"
# NOTE: Textractor loads the REGISTERED copy (*.xdll, renamed at registration),
# not the *.dll. Both filenames must carry the same build or sessions silently
# run the other one.
FIXED=""
for cand in "$VDIR/textractor_websocket_x86.fixed.dll" "$VDIR/bridge-fixed/textractor_websocket_x86.dll"; do
  [ -f "$cand" ] && FIXED="$cand" && break
done
if [ "$BRIDGE" = "fixed" ]; then
  [ -n "$FIXED" ] || { echo "fixed bridge requested but no fixed DLL in $VDIR (fetch with --bridge fixed)" >&2; exit 1; }
  cp -f "$FIXED" "$DST/textractor_websocket_x86.dll"
  cp -f "$FIXED" "$DST/textractor_websocket_x86.xdll"
  echo "bridge: FIXED fork (sha256 $(sha256sum "$DST/textractor_websocket_x86.dll" | cut -c1-12))"
elif [ -f "$VDIR/ws-x86/textractor_websocket_x86.dll" ]; then
  cp -f "$VDIR/ws-x86/textractor_websocket_x86.dll" "$DST/textractor_websocket_x86.dll"
  cp -f "$VDIR/ws-x86/textractor_websocket_x86.dll" "$DST/textractor_websocket_x86.xdll"
  echo "bridge: stock 0.2.0"
fi
echo "installed Textractor x86 -> $DST ($(ls "$DST" | wc -l) entries)"
for f in Textractor.exe TextractorCLI.exe texthook.dll textractor_websocket_x86.dll \
         Qt5Core.dll Qt5Gui.dll Qt5Widgets.dll platforms/qwindows.dll; do
  [ -e "$DST/$f" ] && echo "  ok: $f" || echo "  MISSING: $f"
done
