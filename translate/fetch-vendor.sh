#!/bin/bash
# fetch-vendor.sh — download pinned VN-translate vendor binaries (never committed).
# All artifacts are checksum-verified. Override versions via env (see pins below).
# Usage: fetch-vendor.sh [--dir DIR] [--bridge fixed|stock] [--dlx] [--all]
#   default: Textractor x86 bundle + websocket x86 (+ x64 if --all), no DLX.
#   --bridge fixed: fetch the hardened bridge from the anime4k release asset
#     (TRANSLATE_RELEASE_TAG, default: translate-v2); falls back to stock.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
VDIR="${VENDOR_DIR:-$HERE/vendor}"
BRIDGE="stock"
DLX=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) VDIR="$2"; shift 2 ;;
    --bridge) BRIDGE="$2"; shift 2 ;;
    --dlx) DLX=1; shift ;;
    --all) ALL=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
mkdir -p "$VDIR"
# dl <url> <sha256|""> <dest>: empty sha means unverified (fallback only).
dl() {
  local url="$1" sha="$2" dest="$3" tmp="$3.dl-tmp"
  if [ -f "$dest" ] && { [ -z "$sha" ] || [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$sha" ]; }; then
    echo "cached: $(basename "$dest")"
    return 0
  fi
  echo "fetching $(basename "$dest")…"
  curl -fL --retry 3 -o "$tmp" "$url" || { rm -f "$tmp"; return 1; }
  if [ -n "$sha" ]; then
    [ "$(sha256sum "$tmp" 2>/dev/null | cut -d' ' -f1)" = "$sha" ] \
      || { echo "checksum MISMATCH: $dest" >&2; rm -f "$tmp"; return 1; }
  fi
  mv "$tmp" "$dest"
}
gh_latest_tag() {
  curl -sL -o /dev/null -w '%{url_effective}' --max-time 30 \
    "https://github.com/$1/releases/latest" | sed 's|.*/tag/||'
}

# Pins (bump together with the sha256 below).
TRX_TAG="${TRX_TAG:-dev}"
TRX_ZIP="Textractor_260801.zip"
TRX_URL="https://github.com/Chenx221/Textractor/releases/download/${TRX_TAG}/${TRX_ZIP}"
TRX_SHA="86346c71ba961e993b8b40419d8720204ccaf8fe20606bbd267eb765ba2ff2ef"
WS_TAG="${WS_TAG:-0.2.0}"
WS86_URL="https://github.com/kuroahna/textractor_websocket/releases/download/${WS_TAG}/textractor_websocket_x86.zip"
WS86_SHA="4e28ae0661433caa5d31904430650be1a81c47c80d63f5ddb0ba93470c150875"
WS64_URL="https://github.com/kuroahna/textractor_websocket/releases/download/${WS_TAG}/textractor_websocket_x64.zip"
WS64_SHA="16bbad511d0a43fa0e686144c4a507ec307745dba51f166fa822a094a26c75bf"
DLX_TAG="${DLX_TAG:-v1.2.4}"
DLX_URL="https://github.com/OwO-Network/DLX/releases/download/${DLX_TAG}/deeplx_linux_amd64"
DLX_SHA="eb4b99aec7b1b20bbbebc7e9a780fd970342f0e53d45999608d9d82a5d794dff"

# Textractor: pinned asset first; if upstream renamed/moved it, resolve the
# latest release asset (unverified — warn loudly).
if ! dl "$TRX_URL" "$TRX_SHA" "$VDIR/$TRX_ZIP"; then
  echo "warning: pinned Textractor asset unavailable ($TRX_ZIP @ $TRX_TAG)" >&2
  _tag="$(gh_latest_tag Chenx221/Textractor || true)"
  _asset=""
  if [ -n "$_tag" ]; then
    _asset="$(curl -sL --max-time 30 \
      "https://github.com/Chenx221/Textractor/releases/expanded_assets/${_tag}" \
      | grep -oE 'Textractor[^"'"'"'/ ]*\.zip' | sort -u | tail -n1)"
  fi
  if [ -n "$_asset" ]; then
    echo "  falling back to latest asset: $_asset (checksum UNVERIFIED)" >&2
    dl "https://github.com/Chenx221/Textractor/releases/download/${_tag}/${_asset}" "" "$VDIR/$_asset" \
      || { echo "error: Textractor download failed" >&2; exit 1; }
    TRX_ZIP="$_asset"
  else
    echo "error: no Textractor release asset found (network offline or upstream changed)" >&2
    exit 1
  fi
  unset _tag _asset
fi
dl "$WS86_URL" "$WS86_SHA" "$VDIR/textractor_websocket_x86.zip"
[ "${ALL:-0}" = "1" ] && dl "$WS64_URL" "$WS64_SHA" "$VDIR/textractor_websocket_x64.zip"
[ "$DLX" = "1" ] && { dl "$DLX_URL" "$DLX_SHA" "$VDIR/deeplx_linux_amd64"; chmod +x "$VDIR/deeplx_linux_amd64"; }

# Hardened bridge v2: anime4k release asset (preferred) — falls back to stock + warning.
# v2 = host-safety patches + thread-tagged broadcast (~#num[*]~addr~name~text),
# needed by the native thread picker. Publish the DLL as release tag translate-v2.
FIXED_SHA="acc84db3227dc833a4895b6242c1e3fb0353bd87a43a730a39a15d853006b114"
if [ "$BRIDGE" = "fixed" ]; then
  TAG="${TRANSLATE_RELEASE_TAG:-translate-v2}"
  FIXED_URL="https://github.com/Darkiu1337/anime4k-restore-linux/releases/download/${TAG}/textractor_websocket_x86.dll"
  if ! dl "$FIXED_URL" "$FIXED_SHA" "$VDIR/textractor_websocket_x86.fixed.dll"; then
    echo "warning: fixed bridge asset unavailable (release '${TAG}' not published?); using the stock bridge" >&2
    echo "  the in-app Text Hooker picker needs v2: publish the '${TAG}' release asset, or drop the" >&2
    echo "  DLL at $VDIR/textractor_websocket_x86.fixed.dll and re-run install-textractor.sh" >&2
  fi
fi
# Extract into the layout install-textractor.sh consumes (idempotent).
if command -v python3 >/dev/null 2>&1; then
python3 - "$VDIR" <<'PYEOF'
import glob
import os
import sys
import zipfile

vdir = sys.argv[1]


def unzip(path, dest):
    if os.path.exists(dest):
        return
    with zipfile.ZipFile(path) as z:
        z.extractall(dest)


# Any capitalized Textractor_*.zip (pinned or latest-release fallback). Lowercase
# websocket bundles never match this pattern.
for trx in sorted(glob.glob(os.path.join(vdir, "Textractor*.zip"))):
    unzip(trx, os.path.join(vdir, "textractor-full"))
    break
for name in ("textractor_websocket_x86.zip", "textractor_websocket_x64.zip"):
    p = os.path.join(vdir, name)
    if os.path.exists(p):
        unzip(p, os.path.join(vdir, os.path.splitext(name)[0].replace("textractor_websocket_", "ws-")))
PYEOF
fi
echo "vendor ready in $VDIR"
