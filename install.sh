#!/bin/bash
# install.sh — set up anime4k-restore-linux on this machine.
# Idempotent: safe to re-run; never overwrites user config/library.
# Usage: ./install.sh [--check-only] [--dry-run] [--desktop] [--no-symlink] [-y]

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHECK_ONLY=0; DRY_RUN=0; DESKTOP=0; SYMLINK=1; ASSUME_YES=0
for a in "$@"; do
  case "$a" in
    --check-only) CHECK_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --desktop) DESKTOP=1 ;;
    --no-symlink) SYMLINK=0 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --help|-h) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown option $a" >&2; exit 1 ;;
  esac
done

# Test seam: point the distro detection at another os-release.
OS_RELEASE="${ANIME4K_OS_RELEASE:-/etc/os-release}"

tty_readable() {
  # True when /dev/tty can actually be opened (a -r test is not enough:
  # without a controlling terminal the node is still "readable" but
  # opening it fails with ENXIO).
  [ -c /dev/tty ] && { true </dev/tty; } 2>/dev/null
}

confirm() {
  # Default Yes: this script exists to install things.
  # Reads from /dev/tty so pacman sub-prompts can't steal the answer,
  # and empty input (just Enter) means Yes.
  if [ "$ASSUME_YES" = "1" ]; then return 0; fi
  local ans
  while true; do
    printf '%s [Y/n] ' "$1"
    if tty_readable; then
      read -r ans </dev/tty || ans=""
    else
      read -r ans || ans=""
    fi
    case "$ans" in
      ""|[Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]) return 1 ;;
      *) echo "  please answer y or n." ;;
    esac
  done
}

confirm_no() {
  # Default No: for big/optional steps (multi-hundred-MB downloads).
  if [ "$ASSUME_YES" = "1" ]; then return 1; fi
  local ans
  while true; do
    printf '%s [y/N] ' "$1"
    if tty_readable; then
      read -r ans </dev/tty || ans=""
    else
      read -r ans || ans=""
    fi
    case "$ans" in
      ""|[Nn]|[Nn][Oo]) return 1 ;;
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      *) echo "  please answer y or n." ;;
    esac
  done
}

vkbasalt_layer_present() {
  # Case-insensitive: the source build installs vkBasalt.json (lowercase v,
  # capital B).
  local _d
  for _d in "$HOME/.config/vulkan/implicit_layer.d" "$HOME/.local/share/vulkan/implicit_layer.d" \
            /usr/local/share/vulkan/implicit_layer.d /usr/share/vulkan/implicit_layer.d; do
    [ -d "$_d" ] || continue
    if find "$_d" -maxdepth 1 -iname '*vkbasalt*.json' -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done
  return 1
}

config_set_key() {
  # Merge one key into ~/.config/anime4k/config.json without touching others.
  python3 - "$HOME/.config/anime4k/config.json" "$1" "$2" <<'EOF'
import json, sys
p, k, v = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(p))
    if not isinstance(d, dict):
        d = {}
except (OSError, ValueError):
    d = {}
d[k] = v
import os
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(d, open(p, "w"), indent=2)
EOF
}

detect_gpu_vendor() {
  # nvidia|amd|intel|unknown — seeds the lib32-vulkan-driver provider so
  # pacman never shows the interactive provider menu.
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    echo "nvidia"; return 0
  fi
  if ls /usr/share/vulkan/icd.d/nvidia_icd*.json >/dev/null 2>&1; then
    echo "nvidia"; return 0
  fi
  if command -v lspci >/dev/null 2>&1; then
    if lspci -nnk 2>/dev/null | grep -qi 'nvidia'; then echo "nvidia"; return 0; fi
    if lspci -nnk 2>/dev/null | grep -qi 'amd\|radeon'; then echo "amd"; return 0; fi
    if lspci -nnk 2>/dev/null | grep -qi 'intel.*vga\|intel.*graphics\|intel.*display'; then echo "intel"; return 0; fi
  fi
  if ls /usr/share/vulkan/icd.d/radeon_icd*.json /usr/share/vulkan/icd.d/amd_icd*.json >/dev/null 2>&1; then
    echo "amd"; return 0
  fi
  if ls /usr/share/vulkan/icd.d/intel_icd*.json /usr/share/vulkan/icd.d/intel_hasvk*.json >/dev/null 2>&1; then
    echo "intel"; return 0
  fi
  echo "unknown"
}

lib32_provider_pkg() {
  case "$(detect_gpu_vendor)" in
    nvidia) echo "lib32-nvidia-utils" ;;
    amd) echo "lib32-vulkan-radeon" ;;
    intel) echo "lib32-vulkan-intel" ;;
    *) echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# Package manager abstraction (Arch/Debian/Ubuntu/Fedora families).
# ---------------------------------------------------------------------------
detect_pm() {
  local id="" like=""
  if [ -r "$OS_RELEASE" ]; then
    id="$(sed -n 's/^ID=//p' "$OS_RELEASE" | head -n1 | tr -d '"')"
    like="$(sed -n 's/^ID_LIKE=//p' "$OS_RELEASE" | head -n1 | tr -d '"')"
  fi
  case " $id $like " in
    *" arch "*|*" manjaro "*|*" endeavouros "*|*" cachyos "*|*" omarchy "*|*" artix "*) echo arch ;;
    *" debian "*|*" ubuntu "*|*" linuxmint "*|*" pop "*|*" kali "*|*" parrot "*|*" neon "*|*" zorin "*|*" elementary "*) echo deb ;;
    *" fedora "*|*" rhel "*|*" centos "*|*" nobara "*|*" bazzite "*) echo fed ;;
    *) echo "" ;;
  esac
}
PM="$(detect_pm)"
case "$PM" in
  arch) PM_NAME="pacman" ;;
  deb)  PM_NAME="apt" ;;
  fed)  PM_NAME="dnf" ;;
  *)    PM_NAME="" ;;
esac

pkg_available() {
  case "$PM" in
    arch) pacman -Si "$1" >/dev/null 2>&1 ;;
    deb)  apt-cache show "$1" >/dev/null 2>&1 ;;
    fed)  dnf -q list --available "$1" >/dev/null 2>&1 ;;
    *)    return 1 ;;
  esac
}

pm_update() {
  case "$PM" in
    deb) echo "refreshing apt package lists..."; sudo apt-get update ;;
    arch) sudo pacman -Sy >/dev/null 2>&1 || true ;;
  esac
}

pm_install_batch() {
  # One transaction. Local .deb/.rpm paths are accepted as arguments too.
  [ "$#" -gt 0 ] || return 0
  case "$PM" in
    arch) sudo pacman -S --needed --noconfirm "$@" ;;
    deb)  sudo apt-get install -y "$@" ;;
    fed)  sudo dnf install -y "$@" ;;
    *)    echo "  no package manager detected — install manually: $*"; return 1 ;;
  esac
}

# Collectors: everything goes into one list + one confirmation.
PKGS=(); PKG_FILES=(); PIP_PKGS=(); NOTES=()
declare -A _seen_pkg=()
add_pkg() {
  local p
  for p in "$@"; do
    [ -n "$p" ] || continue
    [ -n "${_seen_pkg[$p]:-}" ] && continue
    _seen_pkg[$p]=1; PKGS+=("$p")
  done
}
add_pip() { PIP_PKGS+=("$1"); }
add_note() { NOTES+=("$1"); }

# tool -> "arch-pkg deb-pkg fed-pkg"; @gum/@pip:name are special-cased below.
DEPS="python3:python|python3|python3
jq:jq|jq|jq
git:git|git|git
curl:curl|curl|curl
zenity:zenity|zenity|zenity
gum:gum|@gum|gum
mangohud:mangohud|mangohud|mangohud
vkcube:vulkan-tools|vulkan-tools|vulkan-tools
icoextract:icoextract|python3-icoextract|@pip:icoextract"

pm_col() {
  # Column for the detected PM ("" when unknown).
  case "$PM" in arch) echo "$1" ;; deb) echo "$2" ;; fed) echo "$3" ;; *) echo "" ;; esac
}

# GitHub release helpers (no -I: curl -I prints headers to stdout and corrupts
# the captured tag — the bug that aborted installs).
gh_latest_tag() {
  curl -sL -o /dev/null -w '%{url_effective}' --max-time 30 \
    "https://github.com/$1/releases/latest" | sed 's|.*/tag/||'
}
fetch_latest_asset() {
  # <repo> <ERE over the expanded-assets page> -> asset name
  local repo="$1" re="$2" tag
  tag="$(gh_latest_tag "$repo")"
  [ -n "$tag" ] || return 1
  curl -sL --max-time 30 "https://github.com/$repo/releases/expanded_assets/$tag" \
    | grep -oE "$re" | sort -u | tail -n1
}
download_asset() {
  # <repo> <asset> <destdir>
  local repo="$1" asset="$2" dest="$3" tag
  tag="$(gh_latest_tag "$repo")"
  curl -L --retry 3 --retry-all-errors --max-time 300 \
    -o "$dest/$asset" "https://github.com/$repo/releases/download/$tag/$asset"
}

umu_deb_suffix() {
  # umu publishes per-Debian/Ubuntu release .debs; pick the closest match.
  local id="" codename="" vid=""
  if [ -r "$OS_RELEASE" ]; then
    id="$(sed -n 's/^ID=//p' "$OS_RELEASE" | head -n1 | tr -d '"')"
    codename="$(sed -n 's/^VERSION_CODENAME=//p' "$OS_RELEASE" | head -n1 | tr -d '"')"
    vid="$(sed -n 's/^VERSION_ID=//p' "$OS_RELEASE" | head -n1 | tr -d '"')"
  fi
  case "$id" in
    ubuntu)
      case "$codename" in
        resolute) echo "ubuntu-resolute" ;;
        *)        echo "ubuntu-noble" ;;
      esac ;;
    debian)
      case "$vid" in
        13|14) echo "debian-13" ;;
        *)     echo "debian-12" ;;
      esac ;;
    *) echo "ubuntu-noble" ;;
  esac
}
fedora_major() {
  sed -n 's/^VERSION_ID=//p' "$OS_RELEASE" 2>/dev/null | head -n1 | tr -d '"' | cut -d. -f1
}

missing=0

# --- core CLI tools --------------------------------------------------------
while IFS=: read -r tool pkgs; do
  # Strip whitespace: the herestring below left-pads the first row.
  tool="${tool//[[:space:]]/}"
  [ -z "$tool" ] && continue
  if command -v "$tool" >/dev/null 2>&1; then
    echo "ok: $tool"
    continue
  fi
  echo "missing: $tool"
  missing=1
  [ "$CHECK_ONLY" = "1" ] && continue
  arch_p="${pkgs%%|*}"; rest="${pkgs#*|}"; deb_p="${rest%%|*}"; fed_p="${rest##*|}"
  p="$(pm_col "$arch_p" "$deb_p" "$fed_p")"
  case "$p" in
    "@gum")
      if [ "$PM" = "deb" ]; then WANT_GUM_DEB=1; else add_pkg gum; fi
      ;;
    "@pip:"*) add_pip "${p#@pip:}" ;;
    ""|"-") add_note "$tool (see requirements.md)" ;;
    *) add_pkg $p ;;
  esac
done <<EOF
 $DEPS
EOF

# --- python imports (no CLI to probe) --------------------------------------
check_pyimport() { # <module> <label> <arch> <deb> <fed>
  if python3 -c "import $1" 2>/dev/null; then
    echo "ok: $2"
    return 0
  fi
  echo "missing: $2"
  missing=1
  [ "$CHECK_ONLY" = "1" ] && return 0
  local p; p="$(pm_col "$3" "$4" "$5")"
  [ -n "$p" ] && add_pkg $p
}
check_pyimport websocket "python-websocket-client (translation bridge client)" \
  python-websocket-client python3-websocket python3-websocket-client
check_pyimport requests "python-requests (DeepL browser automation)" \
  python-requests python3-requests python-requests

# --- Chromium browser (DeepL CDP automation target) ------------------------
_chromium_default_bin() {
  command -v xdg-settings >/dev/null 2>&1 || return 0
  local id desktop exe d
  id="$(xdg-settings get default-web-browser 2>/dev/null)" || return 0
  [ -n "$id" ] || return 0
  for d in "$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications; do
    if [ -f "$d/$id" ]; then desktop="$d/$id"; break; fi
  done
  [ -n "$desktop" ] || return 0
  exe="$(grep -m1 '^Exec=' "$desktop" | cut -d= -f2- | awk '{print $1}')"
  [ -n "$exe" ] || return 0
  case "$exe" in
    /*) [ -x "$exe" ] && printf '%s' "$exe" ;;
    *) command -v "$exe" 2>/dev/null ;;
  esac
}
_chromium_is() {
  [ -n "$1" ] && [ -x "$1" ] || return 1
  "$1" --version 2>/dev/null | grep -qi "chromium\|chrome\|brave\|vivaldi\|opera\|edge"
}
_chromium_any_present() {
  local c
  c="$(_chromium_default_bin)" || true
  if _chromium_is "$c"; then return 0; fi
  for c in brave brave-browser brave-origin chromium chromium-browser google-chrome google-chrome-stable chrome microsoft-edge microsoft-edge-stable vivaldi opera; do
    c="$(command -v "$c" 2>/dev/null)" || continue
    if _chromium_is "$c"; then return 0; fi
  done
  return 1
}
if _chromium_any_present; then
  echo "ok: chromium browser (translation CDP target)"
else
  echo "missing: chromium browser (translation needs one for DeepL automation)"
  missing=1
  if [ "$CHECK_ONLY" = "0" ]; then
    case "$PM" in
      arch|fed) add_pkg chromium ;;
      deb)
        # Ubuntu's 'chromium-browser' is a snap stub whose CDP smoke test fails;
        # don't auto-install it. Debian ships a real 'chromium'.
        if grep -qi ubuntu "$OS_RELEASE" 2>/dev/null; then
          add_note "Chromium browser (Ubuntu's chromium is a snap; install Brave/Chromium from a repo or .deb)"
        else
          add_pkg chromium
        fi
        ;;
      *) add_note "Chromium browser" ;;
    esac
  fi
fi

# --- umu-launcher (Proton runner backend) ----------------------------------
if command -v umu-run >/dev/null 2>&1; then
  echo "ok: umu-run"
elif [ "$CHECK_ONLY" = "1" ]; then
  echo "note: umu-run not found (needed for the proton runner; see requirements.md)"
else
  echo "missing: umu-run (proton runner)"
  case "$PM" in
    arch)
      if pacman -Si umu-launcher >/dev/null 2>&1; then
        add_pkg umu-launcher
        _present=0
        for _p in lib32-nvidia-utils lib32-vulkan-radeon lib32-vulkan-intel lib32-vulkan-nouveau \
                  lib32-vulkan-swrast lib32-vulkan-virtio lib32-vulkan-broadcom lib32-vulkan-freedreno \
                  lib32-vulkan-panfrost lib32-vulkan-asahi lib32-vulkan-dzn lib32-vulkan-gfxstream \
                  lib32-vulkan-powervr; do
          pacman -Q "$_p" >/dev/null 2>&1 && { _present=1; break; }
        done
        if [ "$_present" = "0" ]; then
          _prov="$(lib32_provider_pkg)"
          if [ -n "$_prov" ]; then
            add_pkg "$_prov"
          else
            add_note "lib32-vulkan-driver provider (pacman may ask; NVIDIA: lib32-nvidia-utils, AMD: lib32-vulkan-radeon, Intel: lib32-vulkan-intel)"
          fi
        fi
        unset _present _p _prov
      else
        add_note "umu-launcher (enable [multilib] in /etc/pacman.conf, then re-run)"
      fi
      ;;
    deb) WANT_UMU_DEB=1 ;;
    fed) WANT_UMU_RPM=1 ;;
    *) add_note "umu-launcher (https://github.com/Open-Wine-Components/umu-launcher)" ;;
  esac
fi

# --- vkBasalt (filter runtime): distro package first, else source build ----
VKBASALT_ACTION=""
if vkbasalt_layer_present; then
  echo "ok: vkbasalt (system layer registered)"
elif [ "$CHECK_ONLY" = "1" ]; then
  echo "note: no system vkBasalt layer found (see install pointers above)."
elif [ "$PM" = "arch" ]; then
  _vh=""
  command -v yay >/dev/null 2>&1 && _vh="yay"
  [ -z "$_vh" ] && command -v paru >/dev/null 2>&1 && _vh="paru"
  if [ -n "$_vh" ] && "$_vh" -Si vkbasalt >/dev/null 2>&1; then
    VKBASALT_ACTION="aur"; VKBASALT_HELPER="$_vh"
  else
    VKBASALT_ACTION="source"
    add_pkg meson ninja glslang spirv-headers vulkan-headers pkgconf gcc
  fi
  unset _vh
else
  if { [ "$PM" = "deb" ] && pkg_available vkbasalt && add_pkg vkbasalt; } \
     || { [ "$PM" = "fed" ] && pkg_available vkBasalt && add_pkg vkBasalt; }; then
    :
  else
    VKBASALT_ACTION="source"
    case "$PM" in
      deb) add_pkg meson ninja-build glslang-tools spirv-headers libvulkan-dev pkg-config build-essential ;;
      fed) add_pkg meson ninja-build glslang spirv-headers vulkan-headers pkgconf gcc gcc-c++ ;;
    esac
  fi
fi

# --- GUI (PySide6 + Qt Quick QML modules; KDE style optional) --------------
PYSIDE_PIP=0
if [ -f "$ROOT/gui/app.py" ]; then
  if python3 -c "import PySide6" 2>/dev/null; then
    echo "ok: PySide6 (GUI)"
  else
    echo "missing: PySide6 (GUI)"
    missing=1
    if [ "$CHECK_ONLY" = "0" ]; then
      case "$PM" in
        arch) add_pkg pyside6 ;;
        deb|fed) PYSIDE_PIP=1; add_pip PySide6; add_pkg python3-pip ;;
        *) add_note "PySide6 (pip install PySide6)" ;;
      esac
    fi
  fi
fi

_qmlmod_ok() {
  local base="$1" mod="$2"
  [ -d "$base/$mod" ] || return 1
  find "$base/$mod" -maxdepth 1 \( -name 'qmldir' -o -name '*.so' \) -print -quit 2>/dev/null | grep -q .
}
if [ -f "$ROOT/gui/app.py" ] && [ "$PYSIDE_PIP" = "0" ]; then
  # QtQuick QML modules (GUI + textbox): the QML files (Controls, Layouts,
  # Dialogs pickers, Effects shadow) live in the system qt6-declarative.
  _qmldir="$(python3 -c "from PySide6.QtCore import QLibraryInfo; print(QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath))" 2>/dev/null || true)"
  _qmlmiss=""
  if [ -z "$_qmldir" ]; then
    _qmlmiss="QtQuick Controls Layouts Dialogs Effects (no QML import path)"
  else
    for _m in QtQuick QtQuick/Controls QtQuick/Layouts QtQuick/Dialogs QtQuick/Effects; do
      _qmlmod_ok "$_qmldir" "$_m" || _qmlmiss="$_qmlmiss ${_m##*/}"
    done
  fi
  if [ -z "$_qmlmiss" ]; then
    echo "ok: QtQuick QML modules (Controls/Layouts/Dialogs/Effects)"
  else
    echo "missing: QML modules:$_qmlmiss (the GUI and translation textbox need them)"
    missing=1
    if [ "$CHECK_ONLY" = "0" ]; then
      case "$PM" in
        arch) add_pkg qt6-declarative ;;
        deb)
          for _m in qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
                    qml6-module-qtquick-dialogs qml6-module-qtquick-effects; do
            pkg_available "$_m" && add_pkg "$_m"
          done
          unset _m
          ;;
        fed) pkg_available qt6-qtdeclarative && add_pkg qt6-qtdeclarative ;;
        *) add_note "Qt6 QML modules (see requirements.md)" ;;
      esac
    fi
  fi
  unset _qmldir _qmlmiss _m
  # KDE Quick Controls style (optional): follows kdeglobals; else Fusion.
  _qmldir2="$(python3 -c "from PySide6.QtCore import QLibraryInfo; print(QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath))" 2>/dev/null || true)"
  if [ -n "$_qmldir2" ] && [ -d "$_qmldir2/org/kde/desktop" ]; then
    echo "ok: KDE Quick Controls style (org.kde.desktop)"
  else
    echo "note: org.kde.desktop QML style not found — the GUI/textbox fall back to Fusion"
    if [ "$CHECK_ONLY" = "0" ]; then
      case "$PM" in
        arch) pkg_available qqc2-desktop-style && add_pkg qqc2-desktop-style ;;
        deb)  pkg_available qqc2-desktop-style && add_pkg qqc2-desktop-style ;;
        fed)  for _c in kf6-qqc2-desktop-style qqc2-desktop-style; do
                pkg_available "$_c" && { add_pkg "$_c"; break; }
              done ;;
      esac
      unset _c
    fi
  fi
  unset _qmldir2
fi

# pip-based deps (PySide6/icoextract off-Arch) need pip itself.
if [ "${#PIP_PKGS[@]}" -gt 0 ] && [ "$CHECK_ONLY" = "0" ]; then
  case "$PM" in
    deb|fed) add_pkg python3-pip ;;
  esac
fi

# ---------------------------------------------------------------------------
# One confirmation: print exactly what will be installed, then one transaction.
# ---------------------------------------------------------------------------
if [ "$CHECK_ONLY" = "0" ]; then
  _want_assets=0
  { [ -n "${WANT_GUM_DEB:-}" ] || [ -n "${WANT_UMU_DEB:-}" ] || [ -n "${WANT_UMU_RPM:-}" ]; } && _want_assets=1
  if [ "${#PKGS[@]}" -gt 0 ] || [ "${#PIP_PKGS[@]}" -gt 0 ] || [ "$_want_assets" = "1" ]; then
    echo
    if [ "$DRY_RUN" = "1" ]; then
      echo "Would install${PM_NAME:+ ($PM_NAME)}:"
    else
      echo "The following will be installed${PM_NAME:+ ($PM_NAME)}:"
    fi
    [ "${#PKGS[@]}" -gt 0 ] && printf '  %s\n' "${PKGS[@]}"
    [ -n "${WANT_GUM_DEB:-}" ] && echo "  gum (.deb from charmbracelet/gum)"
    [ -n "${WANT_UMU_DEB:-}" ] && echo "  umu-launcher (.deb, matches your Debian/Ubuntu)"
    [ -n "${WANT_UMU_RPM:-}" ] && echo "  umu-launcher (.rpm, matches your Fedora)"
    [ "${#PIP_PKGS[@]}" -gt 0 ] && printf '  %s (pip)\n' "${PIP_PKGS[@]}"
    [ -n "$VKBASALT_ACTION" ] && [ "$VKBASALT_ACTION" = "aur" ] && echo "  vkbasalt (AUR via $VKBASALT_HELPER)"
    [ -n "$VKBASALT_ACTION" ] && [ "$VKBASALT_ACTION" = "source" ] && echo "  vkbasalt (build from source into ~/.local)"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  (dry run: nothing installed)"
    elif confirm "install all of the above?"; then
      _tmp="$(mktemp -d)"; trap 'rm -rf "$_tmp"' EXIT
      command -v curl >/dev/null 2>&1 || pm_install_batch curl || true
      if [ -n "${WANT_GUM_DEB:-}" ]; then
        if _a="$(fetch_latest_asset charmbracelet/gum 'gum_[0-9.]+_amd64\.deb')" && \
           download_asset charmbracelet/gum "$_a" "$_tmp"; then
          PKG_FILES+=("$_tmp/$_a")
        else
          add_note "gum (release .deb download failed; see requirements.md)"
        fi
      fi
      if [ -n "${WANT_UMU_DEB:-}" ]; then
        _sfx="$(umu_deb_suffix)"
        for _re in "python3-umu-launcher_[^\"']*_amd64_${_sfx}\.deb" "umu-launcher_[^\"']*_all_${_sfx}\.deb"; do
          _a="$(fetch_latest_asset Open-Wine-Components/umu-launcher "$_re")" || continue
          download_asset Open-Wine-Components/umu-launcher "$_a" "$_tmp" && PKG_FILES+=("$_tmp/$_a")
        done
        [ "${#PKG_FILES[@]}" -gt 0 ] || add_note "umu-launcher (.deb download failed)"
        unset _sfx _re _a
      fi
      if [ -n "${WANT_UMU_RPM:-}" ]; then
        _ver="$(fedora_major)"
        _a="$(fetch_latest_asset Open-Wine-Components/umu-launcher "umu-launcher-[^\"']*\.fc${_ver}\.[^\"']*\.rpm")"
        if [ -n "$_a" ] && download_asset Open-Wine-Components/umu-launcher "$_a" "$_tmp"; then
          PKG_FILES+=("$_tmp/$_a")
        else
          add_note "umu-launcher (.rpm for fc${_ver} not found)"
        fi
        unset _ver _a
      fi
      pm_update
      if [ "${#PKGS[@]}" -gt 0 ] || [ "${#PKG_FILES[@]}" -gt 0 ]; then
        pm_install_batch "${PKGS[@]}" "${PKG_FILES[@]}" \
          || echo "  package install reported an error (continuing; re-run to retry)"
      fi
      for _p in "${PIP_PKGS[@]}"; do
        python3 -m pip install --user "$_p" 2>/dev/null \
          || python3 -m pip install --user --break-system-packages "$_p" 2>/dev/null \
          || echo "  pip install $_p failed (GUI may not start)"
      done
      unset _p
      rm -rf "$_tmp"; trap - EXIT; unset _tmp
    else
      echo "  skipped package install"
    fi
  fi
  if [ "${#NOTES[@]}" -gt 0 ]; then
    echo
    echo "manual installs still needed:"
    printf '  %s\n' "${NOTES[@]}"
  fi
fi

# --- vkBasalt after the batch: AUR or source when the layer is still absent -
if [ "$CHECK_ONLY" = "0" ] && [ "$DRY_RUN" = "0" ] && ! vkbasalt_layer_present && [ -n "$VKBASALT_ACTION" ]; then
  if [ "$VKBASALT_ACTION" = "aur" ]; then
    echo "installing vkbasalt from AUR ($VKBASALT_HELPER)..."
    "$VKBASALT_HELPER" -S --needed --noconfirm --answerclean None --answerdiff None vkbasalt \
      || { echo "  AUR install failed — falling back to source build."; VKBASALT_ACTION="source"; }
  fi
  if ! vkbasalt_layer_present && [ "$VKBASALT_ACTION" = "source" ]; then
    if [ "$PM" = "arch" ] || [ "$PM" = "deb" ] || [ "$PM" = "fed" ]; then
      echo "building vkBasalt from source into ~/.local..."
      _vbdir="$(mktemp -d)"
      trap 'rm -rf "$_vbdir"' EXIT
      git clone --depth 1 --recurse-submodules https://github.com/DadSchoorse/vkBasalt.git "$_vbdir/vkbasalt" \
        || { echo "error: clone failed" >&2; exit 1; }
      export PATH="$HOME/.local/bin:$PATH"
      meson setup "$_vbdir/vkbasalt/build" "$_vbdir/vkbasalt" --prefix="$HOME/.local" \
        || { echo "error: meson setup failed (missing build dep?)" >&2; exit 1; }
      ninja -C "$_vbdir/vkbasalt/build" || { echo "error: build failed" >&2; exit 1; }
      meson install -C "$_vbdir/vkbasalt/build" || { echo "error: install failed" >&2; exit 1; }
      # Upstream installs a relative library_path, which the loader cannot
      # resolve outside ld paths: pin it to the absolute installed .so.
      _vklib="$HOME/.local/lib/libvkbasalt.so"
      _vkjson="$HOME/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
      [ -f "$_vklib" ] || { echo "error: expected $_vklib after install" >&2; exit 1; }
      if [ -f "$_vkjson" ]; then
        sed -i -e "s|\"library_path\": *\"[^\"]*\"|\"library_path\": \"$_vklib\"|" "$_vkjson"
      fi
      unset _vklib _vkjson
      rm -rf "$_vbdir"; trap - EXIT; unset _vbdir
      mkdir -p "$HOME/.local/share/vkBasalt"
      touch "$HOME/.local/share/vkBasalt/.anime4k-installed"
      mkdir -p "$HOME/.config/anime4k"
      config_set_key layer_dir "$HOME/.local/share/vulkan/implicit_layer.d"
      echo "ok: vkbasalt built + installed to ~/.local (layer_dir recorded in config.json)"
    else
      echo "  install vkBasalt manually (see requirements.md), then re-run install.sh."
    fi
  fi
fi

# --- Textbox entry point must stay executable ------------------------------
if [ -x "$ROOT/translate/textbox.py" ]; then
  echo "ok: translate/textbox.py executable"
else
  echo "missing: translate/textbox.py is not executable"
  missing=1
  if [ "$CHECK_ONLY" = "0" ] && [ "$DRY_RUN" = "0" ]; then
    chmod +x "$ROOT/translate/textbox.py" && echo "  fixed with chmod +x" || echo "  chmod failed"
  fi
fi

# ---------------------------------------------------------------------------
# Proton-CachyOS (recommended build): fetched from the upstream release,
# checksum-verified. 32-bit D3D no longer requires it (the runner defaults to
# Wine new WoW64), but it stays the safest verified build. A failure here is
# non-fatal: umu auto-fetches UMU-Proton on first launch.
# ---------------------------------------------------------------------------
CACHYOS_PROTON_NAME="Proton-CachyOS Latest"
CACHYOS_PROTON_DIR="$HOME/.local/share/Steam/compatibilitytools.d/$CACHYOS_PROTON_NAME"
install_cachyos_proton() {
  for t in curl tar; do
    command -v "$t" >/dev/null 2>&1 || { echo "error: '$t' needed for this step" >&2; return 1; }
  done
  local tag asset base
  tag="$(gh_latest_tag CachyOS/proton-cachyos)"
  [ -n "$tag" ] || { echo "error: could not resolve latest proton-cachyos release" >&2; return 1; }
  echo "latest proton-cachyos: $tag"
  # The tag already carries the "cachyos-" prefix, so the asset is
  # "proton-<tag>-...", not "proton-cachyos-<tag>-...".
  local v3=""
  if grep -q avx2 /proc/cpuinfo 2>/dev/null && grep -q bmi2 /proc/cpuinfo 2>/dev/null; then
    v3="_v3"
  fi
  asset="proton-${tag}-x86_64${v3}.tar.xz"
  base="https://github.com/CachyOS/proton-cachyos/releases/download/${tag}"
  # Asset suffixes drifted across releases; fall back to scraping the page,
  # honouring the CPU capability so a non-v3 host never grabs a v3 build.
  if ! curl -sfI --max-time 30 -o /dev/null "$base/$asset" >/dev/null 2>&1; then
    echo "  ($asset not found, resolving from release page...)"
    # Exclude "/" so the repo path in the href can't be mistaken for the asset.
    archive_re="proton-cachyos-[0-9][^\"'/ ]*x86_64${v3}\.tar\.xz"
    asset="$(curl -sL --max-time 30 \
      "https://github.com/CachyOS/proton-cachyos/releases/expanded_assets/${tag}" \
      | grep -oE "$archive_re" | sort -u | tail -n1)"
    [ -n "$asset" ] || { echo "error: no x86_64${v3} proton-cachyos asset for $tag" >&2; return 1; }
  fi
  echo "downloading $asset (~1GB, one time)..."
  local tmp sha
  tmp="$(mktemp -d)"
  curl -L -C - --retry 5 --retry-all-errors --speed-limit 10240 --speed-time 30 \
    -o "$tmp/$asset" "$base/$asset" || { echo "error: download failed" >&2; rm -rf "$tmp"; return 1; }
  [ -s "$tmp/$asset" ] || { echo "error: empty download" >&2; rm -rf "$tmp"; return 1; }
  sha="${asset%.tar.*}.sha512sum"
  if curl -sL --max-time 60 -o "$tmp/$sha" "$base/$sha"; then
    ( cd "$tmp" && sha512sum -c "$sha" ) \
      || { echo "error: checksum mismatch (redownload or check the release page)" >&2; rm -rf "$tmp"; return 1; }
  else
    echo "  warning: no checksum published, skipping verification"
  fi
  tar -xf "$tmp/$asset" -C "$tmp" || { echo "error: extract failed" >&2; rm -rf "$tmp"; return 1; }
  local src
  src="$(find "$tmp" -maxdepth 2 -name proton -type f | head -n 1)"
  [ -n "$src" ] || { echo "error: extracted tree has no proton entrypoint" >&2; rm -rf "$tmp"; return 1; }
  src="$(dirname "$src")"
  mkdir -p "$(dirname "$CACHYOS_PROTON_DIR")"
  rm -rf "$CACHYOS_PROTON_DIR"
  mv "$src" "$CACHYOS_PROTON_DIR"
  rm -rf "$tmp"
  [ -x "$CACHYOS_PROTON_DIR/proton" ] || { echo "error: install landed wrong" >&2; return 1; }
  echo "ok: $CACHYOS_PROTON_NAME installed."
}
seed_proton_default() {
  # Point the config default at the verified build, but never override an
  # existing user choice and only after a successful install. The value is the
  # ABSOLUTE PATH (the runner exports it as PROTONPATH); a bare display name
  # would make umu fail to find Proton (see docs/translate.md / HANDOFF).
  python3 - "$HOME/.config/anime4k/config.json" "$CACHYOS_PROTON_DIR" <<'EOF'
import json, os, sys
p, proton = sys.argv[1], sys.argv[2]
if not proton or not os.path.isdir(proton):
    sys.exit(0)
try:
    d = json.load(open(p))
    if not isinstance(d, dict):
        d = {}
except (OSError, ValueError):
    d = {}
if not d.get("proton"):
    d["proton"] = proton
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(d, open(p, "w"), indent=2)
    print("seeded config proton default: " + os.path.basename(proton))
EOF
}
if [ -x "$CACHYOS_PROTON_DIR/proton" ]; then
  echo "ok: $CACHYOS_PROTON_NAME"
elif [ "$CHECK_ONLY" = "1" ]; then
  echo "note: $CACHYOS_PROTON_NAME not found (recommended; umu falls back to UMU-Proton)"
elif [ "$DRY_RUN" = "1" ]; then
  echo "note: would offer to install $CACHYOS_PROTON_NAME (~1GB)"
elif confirm "install $CACHYOS_PROTON_NAME (verified Proton; ~1GB download)?"; then
  if install_cachyos_proton; then
    seed_proton_default
  else
    echo "  warning: $CACHYOS_PROTON_NAME install failed — continuing."
    echo "  umu will auto-fetch UMU-Proton on first launch; 32-bit D3D filters via the runner's"
    echo "  default Wine new WoW64, so filtering still works (re-run install.sh to retry)."
  fi
else
  echo "  skipped (umu will auto-fetch UMU-Proton; 32-bit D3D filters via new WoW64)"
fi

# --- rpgmaker-linux (RPGMaker runner backend): opt-in, pinned upstream -----
if command -v rpgmaker-linux >/dev/null 2>&1; then
  echo "ok: rpgmaker-linux ($(rpgmaker-linux --version 2>/dev/null | head -n 1))"
else
  echo "optional: rpgmaker-linux not found (needed for the rpgmaker runner)."
  if [ "$CHECK_ONLY" = "0" ] && [ "$DRY_RUN" = "0" ] && confirm_no "install rpgmaker-linux support? (downloads NW.js runtimes, several hundred MB)"; then
    for t in wget tar; do
      command -v "$t" >/dev/null 2>&1 || { echo "error: '$t' needed for this step" >&2; exit 1; }
    done
    _rarch="$(uname -m | sed -e 's/armv7l/armhf/g')"
    _rver="${RPGMAKER_VERSION:-1.1.9}"
    _rtar="rpgmakerlinux-${_rarch}-v${_rver}.tar.gz"
    _rurl="https://github.com/bakustarver/rpgmakermlinux-cicpoffs/releases/download/v${_rver}/${_rtar}"
    _rdir="$(mktemp -d)"
    trap 'rm -rf "$_rdir"' EXIT
    echo "downloading ${_rtar}..."
    wget -P "$_rdir" "$_rurl" || { echo "error: download failed" >&2; exit 1; }
    [ -s "$_rdir/$_rtar" ] || { echo "error: empty download" >&2; exit 1; }
    tar -xf "$_rdir/$_rtar" -C "$_rdir" || { echo "error: extract failed" >&2; exit 1; }
    _rsub="$(find "$_rdir" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
    [ -x "$_rsub/install.sh" ] || { echo "error: bundled installer not found" >&2; exit 1; }
    ( cd "$_rsub" && ./install.sh ) || { echo "error: rpgmaker-linux installer failed" >&2; exit 1; }
    rm -rf "$_rdir"
    trap - EXIT
    unset _rarch _rver _rtar _rurl _rdir _rsub
    command -v rpgmaker-linux >/dev/null 2>&1 && echo "ok: rpgmaker-linux installed." || echo "warning: install finished but rpgmaker-linux not on PATH (restart shell?)"
  else
    echo "  skipped — proton/native runners are unaffected."
  fi
fi

if [ "$CHECK_ONLY" = "1" ]; then
  if [ "$missing" = "0" ]; then
    echo "all required tools present."
  else
    echo "missing tools (see above)."
    exit 1
  fi
  exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "dry run complete (nothing was installed)."
  exit 0
fi

# Deploy shaders (only ours, by exact filename).
SHADER_DST="$HOME/.local/share/gamescope/reshade/Shaders"
mkdir -p "$SHADER_DST"
for f in "$ROOT"/shaders/Anime4K_Restore_*.fx "$ROOT"/shaders/ClearColor.fx; do
  [ -f "$f" ] && cp "$f" "$SHADER_DST/"
done
# Clear-preset manifest (the launchers read the deployed copy if present).
[ -f "$ROOT/shaders/presets.json" ] && cp "$ROOT/shaders/presets.json" "$SHADER_DST/"
echo "shaders deployed to $SHADER_DST (Restore + Clear presets)"

# Config dir + seed config (never overwrite).
mkdir -p "$HOME/.config/anime4k"
if [ ! -f "$HOME/.config/anime4k/config.json" ]; then
  echo '{"_note":"optional overrides: prefix, proton, layer_dir, shader_dir, wow64"}' > "$HOME/.config/anime4k/config.json"
  echo "seeded ~/.config/anime4k/config.json (edit your defaults there)"
fi

# VN translation (translate/): fetch pinned vendor binaries (never committed,
# all checksum-verified) and install the Textractor hook into the shared prefix.
if [ -d "$ROOT/translate" ]; then
  # Seed per-file settings from samples (first run only; never overwrite).
  if [ ! -f "$ROOT/translate/config.json" ] && [ -f "$ROOT/translate/config.json.sample" ]; then
    cp "$ROOT/translate/config.json.sample" "$ROOT/translate/config.json"
    echo "seeded translate/config.json (translator settings; edit to override)"
  fi
  if [ ! -f "$ROOT/translate/translate.json" ] && [ -f "$ROOT/translate/translate.json.sample" ]; then
    cp "$ROOT/translate/translate.json.sample" "$ROOT/translate/translate.json"
    echo "seeded translate/translate.json (games registry; edit exe paths)"
  fi
  # Translation browser: any Chromium works (automation only needs
  # --remote-debugging-port against the isolated debug profile, never the
  # real one). The browser package was already installed in the batch above;
  # here we pick one and CDP-smoke-test it. A configured, still-valid
  # brave_bin is never clobbered.
  translate_config_set_key() {
    python3 - "$ROOT/translate/config.json" "$1" "$2" <<'EOF'
import json, os, sys
p, k, v = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(p))
    if not isinstance(d, dict):
        d = {}
except (OSError, ValueError):
    d = {}
d[k] = v
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(d, open(p, "w"), indent=2)
EOF
  }
  _chromium_smoke() {
    # Headless CDP handshake on a temp port + temp profile. Zero side effects.
    local bin="$1" port tmpd pid
    command -v curl >/dev/null 2>&1 || return 1
    port=$((20000 + RANDOM % 20000))
    tmpd="$(mktemp -d)" || return 1
    "$bin" --headless --no-first-run --remote-debugging-port="$port" \
      --remote-allow-origins="*" --user-data-dir="$tmpd" about:blank >/dev/null 2>&1 &
    pid=$!
    for _ in $(seq 1 20); do
      if curl -sf --max-time 2 "http://127.0.0.1:$port/json/version" >/dev/null 2>&1; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -rf "$tmpd"
        return 0
      fi
      sleep 0.3
    done
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -rf "$tmpd"
    return 1
  }
  _pick_chromium() {
    # Sets TRANSLATE_BROWSER_PICK to the first binary passing sniff + smoke.
    local c
    TRANSLATE_BROWSER_PICK=""
    c="$(_chromium_default_bin)" || true
    if _chromium_is "$c" && _chromium_smoke "$c"; then TRANSLATE_BROWSER_PICK="$c"; return 0; fi
    for c in brave brave-browser brave-origin chromium chromium-browser google-chrome google-chrome-stable chrome microsoft-edge microsoft-edge-stable vivaldi opera; do
      c="$(command -v "$c" 2>/dev/null)" || continue
      if _chromium_is "$c" && _chromium_smoke "$c"; then TRANSLATE_BROWSER_PICK="$c"; return 0; fi
    done
    return 1
  }
  _cfg_browser="$(python3 -c "import json; print(json.load(open('$ROOT/translate/config.json')).get('brave_bin',''))" 2>/dev/null || true)"
  if _chromium_is "$_cfg_browser"; then
    echo "ok: translation browser: $_cfg_browser (configured)"
  elif _pick_chromium; then
    translate_config_set_key brave_bin "$TRANSLATE_BROWSER_PICK"
    echo "translation browser: $TRANSLATE_BROWSER_PICK (CDP smoke-tested, recorded in translate/config.json)"
  else
    echo "warning: no Chromium browser found — DeepL automation needs one."
    echo "  install a Chromium-based browser, then re-run install.sh."
  fi
  unset _cfg_browser TRANSLATE_BROWSER_PICK
  TRANSLATE_BRIDGE="${TRANSLATE_BRIDGE:-fixed}"
  if confirm "install VN translation support (Textractor hook + DeepL bridge)?"; then
    if bash "$ROOT/translate/fetch-vendor.sh" --bridge "$TRANSLATE_BRIDGE"; then
      "$ROOT/translate/install-textractor.sh" --bridge "$TRANSLATE_BRIDGE" \
        || echo "  textractor install failed (see above); re-run install.sh to retry"
    else
      echo "  vendor fetch failed (see above); re-run install.sh to retry"
    fi
  else
    echo "  skipped translation support (re-run install.sh to add later)"
  fi
  if confirm_no "install local DLX server binary (offline DeepL fallback on :1188)?"; then
    if bash "$ROOT/translate/fetch-vendor.sh" --dlx; then
      mkdir -p "$HOME/.local/bin"
      cp -f "$ROOT/translate/vendor/deeplx_linux_amd64" "$HOME/.local/bin/dlx"
      chmod +x "$HOME/.local/bin/dlx"
      echo "installed dlx to ~/.local/bin/dlx (run 'dlx' to serve :1188)"
    fi
  fi

  # Textbox always-on-top: detected per session. The runtime backends need no
  # install (Hyprland hyprctl / KDE qdbus6); GNOME Wayland needs an optional
  # Shell extension. X11 uses Qt's native keep-above hint. See docs/translate.md.
  _ak_gnome_top() {
    local src="$ROOT/translate/gnome-extension/vn-textbox-top@anime4k"
    local dst="$HOME/.local/share/gnome-shell/extensions/vn-textbox-top@anime4k"
    [ -d "$src" ] || return 0
    if ! command -v gnome-extensions >/dev/null 2>&1; then
      echo "  note: gnome-extensions CLI missing; textbox Top stays unsupported"
      return 0
    fi
    if [ "$CHECK_ONLY" = "1" ] || [ "$DRY_RUN" = "1" ]; then
      echo "  would install GNOME Shell extension vn-textbox-top@anime4k"
      return 0
    fi
    if ! confirm_no "install the GNOME Shell extension for textbox always-on-top? (may need re-login)"; then
      echo "  skipped; textbox Top stays unsupported on GNOME Wayland"
      return 0
    fi
    mkdir -p "$dst"
    cp -f "$src/metadata.json" "$src/extension.js" "$dst/" 2>/dev/null || true
    if gnome-extensions enable vn-textbox-top@anime4k 2>/dev/null; then
      echo "  enabled vn-textbox-top@anime4k (log out/in if it does not activate)"
    else
      echo "  installed; enable it in Extensions or: gnome-extensions enable vn-textbox-top@anime4k"
      echo "  note: on GNOME Wayland a log out/in may be required"
    fi
  }
  _ak_wayland=0
  case "${XDG_SESSION_TYPE:-}" in wayland) _ak_wayland=1 ;; esac
  [ -n "${WAYLAND_DISPLAY:-}" ] && _ak_wayland=1
  _ak_desk="$(printf '%s' "${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}" | tr '[:lower:]' '[:upper:]')"
  if [ "$_ak_wayland" = "0" ]; then
    echo "textbox Top: X11 keep-above hint (native)"
  else
    case "$_ak_desk" in
      *HYPRLAND*)
        echo "textbox Top: Hyprland (hyprctl pin/bring-to-top)"
        command -v hyprctl >/dev/null 2>&1 || echo "  note: hyprctl not found; Top will be unavailable" ;;
      *KDE*)
        echo "textbox Top: KDE KWin keep-above (script over qdbus6)"
        if ! command -v qdbus6 >/dev/null 2>&1 && ! command -v qdbus >/dev/null 2>&1; then
          echo "  note: qdbus6 not found; Top will be unavailable"
        fi ;;
      *GNOME*)
        echo "textbox Top: GNOME Wayland (Shell extension required)"
        _ak_gnome_top ;;
      *)
        echo "textbox Top: unavailable on this Wayland compositor (Float still applies)" ;;
    esac
  fi
  unset _ak_wayland _ak_desk
fi

# PATH symlinks (default on): anime4k TUI + GUI entry point.
if [ "$SYMLINK" = "1" ]; then
  mkdir -p "$HOME/.local/bin"
  # A checkout that was moved/renamed after a previous install leaves dangling
  # links here (the targets are absolute). Report them before repointing so a
  # broken `anime4k`/`anime4k-gui` is never silent (docs/limits.md).
  for _l in anime4k anime4k-gui vn-launch vn-textbox vn-translate; do
    _p="$HOME/.local/bin/$_l"
    if [ -L "$_p" ] && [ ! -e "$_p" ]; then
      echo "note: ~/.local/bin/$_l was dangling (-> $(readlink "$_p")); repointing to $ROOT"
    fi
  done
  unset _l _p
  ln -sf "$ROOT/scripts/anime4k" "$HOME/.local/bin/anime4k"
  if [ -f "$ROOT/gui/app.py" ]; then
    ln -sf "$ROOT/gui/app.py" "$HOME/.local/bin/anime4k-gui"
    echo "symlinked: anime4k, anime4k-gui -> ~/.local/bin/"
  else
    echo "symlinked: anime4k -> ~/.local/bin/ (gui not built yet, skipping anime4k-gui)"
  fi
  if [ -d "$ROOT/translate" ]; then
    ln -sf "$ROOT/translate/vn-launch.sh" "$HOME/.local/bin/vn-launch"
    ln -sf "$ROOT/translate/textbox.py" "$HOME/.local/bin/vn-textbox"
    ln -sf "$ROOT/translate/vn_translate.py" "$HOME/.local/bin/vn-translate"
    rm -f "$HOME/.local/bin/vn-textbox-qml"
    echo "symlinked: vn-launch, vn-textbox, vn-translate -> ~/.local/bin/ (translation)"
  fi
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *)
      echo "note: ~/.local/bin is not on your PATH."
      for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && ! grep -q '\.local/bin' "$rc"; then
          if confirm "append ~/.local/bin to PATH in $rc?"; then
            # shellcheck disable=SC2016
            # (single quotes intentional: expand when the rc file is sourced)
            printf '\n# added by anime4k-restore-linux install.sh\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
            echo "  added (restart your shell to take effect)"
          fi
        fi
      done
      ;;
  esac
fi

if [ "$DESKTOP" = "1" ]; then
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/anime4k.desktop" <<EOF2
[Desktop Entry]
Name=Anime4K Launcher
Comment=Launch games with Anime4K Restore filters
Exec=bash -lc '$ROOT/scripts/anime4k'
Terminal=true
Type=Application
Categories=Game;
EOF2
  if [ -f "$ROOT/gui/app.py" ]; then
    cat > "$HOME/.local/share/applications/anime4k-gui.desktop" <<EOF2
[Desktop Entry]
Name=Anime4K Launcher (GUI)
Comment=Launch games with Anime4K Restore filters
Exec=$ROOT/gui/app.py
Terminal=false
Type=Application
Categories=Game;
EOF2
  fi
  echo "desktop entries installed."
fi

echo "done. Try: anime4k"
echo "Verify the filter chain on this machine with: anime4k doctor"
