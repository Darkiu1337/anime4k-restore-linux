#!/bin/bash
# install-textractor.sh — provision Textractor x86 once per machine and link it
# into a Wine prefix.
#
# Textractor lives in a canonical, prefix-independent dir
# (~/.local/share/anime4k/textractor/x86) so the full Qt5 bundle is downloaded
# and stored exactly once. The prefix's drive_c/Textractor is a symlink to that
# canonical dir (copy fallback), so every prefix — including prefixes umu only
# creates on first launch — shares one install and the bundled config.
#
# The extension set is FORCED bridge-only on every run. Textractor loads its
# stock six extensions (Google Translate, Extra Window, ...) whenever
# SavedExtensions.txt is missing, which stalls the sentence pipeline
# (docs/translate.md); we never rely on it being absent.
#
# Usage: install-textractor.sh [--prefix DIR] [--bridge stock|fixed]
#                              [--vendor-dir DIR] [--no-link]
#   Binaries are NEVER committed: run fetch-vendor.sh first (or set VENDOR_DIR).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX=""
BRIDGE="stock"
VDIR="${VENDOR_DIR:-$HERE/vendor}"
LINK=1
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --bridge) BRIDGE="$2"; shift 2 ;;
    --vendor-dir) VDIR="$2"; shift 2 ;;
    --no-link) LINK=0; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
if [ -z "$PREFIX" ]; then
  PREFIX="$(python3 -c "import json; print(json.load(open('$HOME/.config/anime4k/config.json')).get('prefix', ''))" 2>/dev/null || true)"
  [ -n "$PREFIX" ] || PREFIX="$HOME/.local/share/anime4k/prefixes/default"
fi
SRC="$VDIR/textractor-full/x86"
[ -d "$SRC" ] || { echo "missing $SRC (run fetch-vendor.sh first)" >&2; exit 1; }

# Canonical home shared by every prefix. Overridable for tests.
HOME_DIR="${ANIME4K_TEXTTRACTOR_HOME:-$HOME/.local/share/anime4k/textractor}"
DST="$HOME_DIR/x86"
mkdir -p "$DST"
# Refresh the whole bundle (the exe/CLI/texthook are force-copied again below).
# User data (SavedHooks.txt, ...) is not in the bundle, so it survives.
cp -r "$SRC/." "$DST/"
cp -f "$SRC/Textractor.exe" "$SRC/TextractorCLI.exe" "$SRC/texthook.dll" "$DST/"

# NOTE: Textractor loads the REGISTERED copy (*.xdll, renamed at registration),
# not the *.dll. Both filenames must carry the same build or sessions silently
# run the other one.
FIXED=""
for cand in "$VDIR/textractor_websocket_x86.fixed.dll" "$VDIR/bridge-fixed/textractor_websocket_x86.dll"; do
  [ -f "$cand" ] && FIXED="$cand" && break
done
if [ "$BRIDGE" = "fixed" ] && [ -z "$FIXED" ]; then
  echo "warning: fixed bridge requested but no fixed DLL in $VDIR; using the stock bridge" >&2
  echo "  the in-app Text Hooker picker needs v2 (or reveal Textractor via the wizard debug box)" >&2
  BRIDGE="stock"
fi
if [ "$BRIDGE" = "fixed" ]; then
  [ -n "$FIXED" ] || { echo "fixed bridge requested but no fixed DLL in $VDIR (fetch with --bridge fixed)" >&2; exit 1; }
  cp -f "$FIXED" "$DST/textractor_websocket_x86.dll"
  cp -f "$FIXED" "$DST/textractor_websocket_x86.xdll"
  echo "bridge: FIXED fork (sha256 $(sha256sum "$DST/textractor_websocket_x86.dll" | cut -c1-12))"
elif [ -f "$VDIR/ws-x86/textractor_websocket_x86.dll" ]; then
  cp -f "$VDIR/ws-x86/textractor_websocket_x86.dll" "$DST/textractor_websocket_x86.dll"
  cp -f "$VDIR/ws-x86/textractor_websocket_x86.dll" "$DST/textractor_websocket_x86.xdll"
  echo "bridge: stock 0.2.0"
else
  echo "error: no bridge DLL in $VDIR (run fetch-vendor.sh first)" >&2
  exit 1
fi

# Bundled known-good config (translate/textractor-config/). Textractor.ini is a
# starting point only — Textractor rewrites it on exit, so never clobber it.
CFG="$HERE/textractor-config"
if [ -f "$CFG/Textractor.ini" ] && [ ! -f "$DST/Textractor.ini" ]; then
  cp -f "$CFG/Textractor.ini" "$DST/Textractor.ini"
fi
# Always force bridge-only, replacing whatever Textractor wrote on exit. This is
# the actual fix for the stock-extension stall (docs/translate.md).
printf 'textractor_websocket_x86>' > "$DST/SavedExtensions.txt"

# Link the canonical dir into the prefix. A moved/renamed copy is replaced, but
# its saved hooks/games and window config are migrated first so nothing is lost.
if [ "$LINK" = "1" ]; then
  LNK="$PREFIX/drive_c/Textractor"
  mkdir -p "$PREFIX/drive_c"
  if [ -d "$LNK" ] && [ ! -L "$LNK" ]; then
    for f in SavedHooks.txt SavedGames.txt SavedRegexFilters.txt Textractor.ini; do
      [ -f "$LNK/x86/$f" ] || continue
      if [ "$f" = "Textractor.ini" ] && [ -f "$DST/$f" ]; then
        continue
      fi
      cp -f "$LNK/x86/$f" "$DST/$f"
    done
    rm -rf "$LNK"
  fi
  if [ -e "$LNK" ] || [ -L "$LNK" ]; then rm -rf "$LNK"; fi
  if ln -s "$HOME_DIR" "$LNK" 2>/dev/null; then
    echo "linked prefix Textractor -> $HOME_DIR"
  else
    echo "warning: symlink not supported here; copying Textractor into the prefix" >&2
    mkdir -p "$LNK"
    cp -rn "$HOME_DIR/." "$LNK/"
    cp -f "$HOME_DIR/x86/Textractor.exe" "$LNK/x86/" 2>/dev/null || true
  fi
fi

echo "installed Textractor x86 -> $DST ($(ls "$DST" | wc -l) entries)"
for f in Textractor.exe TextractorCLI.exe texthook.dll textractor_websocket_x86.dll \
         Qt5Core.dll Qt5Gui.dll Qt5Widgets.dll platforms/qwindows.dll; do
  [ -e "$DST/$f" ] && echo "  ok: $f" || echo "  MISSING: $f"
done
