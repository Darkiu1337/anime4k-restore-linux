#!/bin/bash
# anime4k-doctor — self-test the Anime4K Restore filter chain without any game.
# Checks, in order: layer manifest, library resolution, shaders, GPUs,
# runner backends, and (with a display) a live vkcube+vkBasalt run.
# Exit 0 = chain ready, 1 = problems found. Never touches user config.
# Usage: anime4k-doctor [--live/--no-live]  (also: anime4k doctor)
_SRC="${BASH_SOURCE[0]}"
while [ -L "$_SRC" ]; do _SRC="$(readlink "$_SRC")"; case "$_SRC" in /*) :;; *) _SRC="$(dirname "${BASH_SOURCE[0]}")/$_SRC";; esac; done
SCRIPT_DIR="$(cd "$(dirname "$_SRC")" && pwd)"
unset _SRC
# shellcheck disable=SC1091
source "$SCRIPT_DIR/anime4k-lib.sh"

LIVE="auto"
while [ $# -gt 0 ]; do
  case "$1" in
    --live) LIVE="yes"; shift ;;
    --no-live) LIVE="no"; shift ;;
    --help|-h) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown option $1 (see --help)" >&2; exit 1 ;;
  esac
done

pass=0
fail=0
ok() { echo "ok: $*"; pass=$((pass + 1)); }
bad() { echo "FAIL: $*"; fail=$((fail + 1)); }
skip() { echo "skip: $*"; }

# 1. Layer manifest (same lookup the launchers use).
MANIFEST=""
if MANIFEST="$(ak_vkbasalt_manifest)"; then
  ok "layer manifest: $MANIFEST"
else
  bad "no vkBasalt layer manifest (set layer_dir in $ANIME4K_CONFIG or install vkbasalt; see requirements.md)"
fi

# 2. Library the manifest points at must exist (catches stale registrations).
LIB=""
if [ -n "$MANIFEST" ] && LIB="$(ak_vkbasalt_lib "$MANIFEST")"; then
  ok "layer library: $LIB ($(file -b "$LIB" 2>/dev/null | cut -d, -f1-2))"
else
  [ -n "$MANIFEST" ] && bad "manifest $MANIFEST points at a missing library (reinstall vkbasalt)"
fi

# 3. Shaders the launchers will reference.
SHADERS_OK=1
for v in S M L Soft_S Soft_L; do
  if [ -f "$ANIME4K_SHADER_DIR/Anime4K_Restore_$v.fx" ]; then
    :
  else
    bad "shader missing: $ANIME4K_SHADER_DIR/Anime4K_Restore_$v.fx"
    SHADERS_OK=0
  fi
done
[ "$SHADERS_OK" = "1" ] && ok "shaders (5 variants) in $ANIME4K_SHADER_DIR"

# 4. GPUs + what the proton runner will default to.
if command -v vulkaninfo >/dev/null 2>&1; then
  echo "GPUs (vulkaninfo):"
  vulkaninfo --summary 2>/dev/null | grep -i "deviceName" | sed 's/^/  /' | sort -u
  pass=$((pass + 1))
else
  skip "vulkaninfo not installed (device list unavailable)"
fi
if DGPU="$(ak_discrete_gpu_name)"; then
  ok "proton DXVK default: discrete GPU '$DGPU'"
else
  echo "note: no discrete GPU detected — proton launches use the loader default (override with --dxvk-device)"
fi

# 5. Runner backends.
if command -v umu-run >/dev/null 2>&1; then
  ok "umu-run (proton runner)"
else
  bad "umu-run missing (proton runner will not work; see requirements.md)"
fi
_CDIR="$HOME/.local/share/Steam/compatibilitytools.d"
if [ -d "$_CDIR" ]; then
  _found=""
  for _p in "$_CDIR"/*/; do
    [ -x "${_p}proton" ] || [ -x "${_p}proton.sh" ] || continue
    _found="${_found:+$_found | }$(basename "$_p")"
  done
  if [ -n "$_found" ]; then
    ok "installed Protons: $_found"
  else
    echo "note: no Proton builds in $_CDIR (umu auto-fetches UMU-Proton on first launch: 64-bit titles filter, 32-bit D3D may not — run install.sh for Proton-CachyOS)"
  fi
else
  echo "note: no compatibilitytools.d yet (umu auto-fetches UMU-Proton on first launch)"
fi
unset _CDIR _found _p
if command -v rpgmaker-linux >/dev/null 2>&1; then
  ok "rpgmaker-linux ($(rpgmaker-linux --version 2>/dev/null | head -n 1))"
else
  echo "note: rpgmaker-linux missing (only the rpgmaker runner needs it)"
fi

# 6. Live chain test: vkcube through the layer with a rendered L config.
if [ "$LIVE" = "no" ]; then
  skip "live vkcube test (--no-live)"
elif [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  skip "live vkcube test (no display)"
elif ! command -v vkcube >/dev/null 2>&1; then
  skip "live vkcube test (vulkan-tools not installed)"
elif ! command -v timeout >/dev/null 2>&1; then
  skip "live vkcube test (coreutils timeout missing)"
elif [ -z "$MANIFEST" ] || [ -z "$LIB" ] || [ "$SHADERS_OK" = "0" ]; then
  skip "live vkcube test (chain above is broken)"
else
  ak_vkbasalt_env L
  _out="$(timeout -s KILL 8 vkcube 2>&1 || true)"
  if printf '%s' "$_out" | grep -q "vkBasalt info"; then
    ok "live chain: vkcube presented through vkBasalt (effect: Anime4K_Restore_L)"
  else
    bad "live chain: vkcube ran but vkBasalt never engaged"
    printf '%s' "$_out" | grep -i -m5 "vkbasalt error" || true
  fi
  unset _out
fi

echo "doctor: $pass passed, $fail failed."
[ "$fail" = "0" ]
