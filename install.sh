#!/bin/bash
# install.sh — set up anime4k-restore-linux on this machine.
# Idempotent: safe to re-run; never overwrites user config/library.
# Usage: ./install.sh [--check-only] [--desktop] [--no-symlink] [-y]
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHECK_ONLY=0; DESKTOP=0; SYMLINK=1; ASSUME_YES=0
for a in "$@"; do
  case "$a" in
    --check-only) CHECK_ONLY=1 ;;
    --desktop) DESKTOP=1 ;;
    --no-symlink) SYMLINK=0 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --help|-h) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown option $a" >&2; exit 1 ;;
  esac
done

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

pacman_install() {
  # Wrapper so interactive pacman prompts always talk to the terminal
  # (never to a pipe/redirected stdin), and -y gets --noconfirm.
  if [ "$ASSUME_YES" = "1" ]; then
    sudo pacman -S --needed --noconfirm "$@"
  elif tty_readable; then
    sudo pacman -S --needed "$@" </dev/tty
  else
    sudo pacman -S --needed "$@"
  fi
}

vkbasalt_layer_present() {
  # Case-insensitive: the source build installs vkBasalt.json (lowercase v,
  # capital B), which the old *vkbasalt*|*VkBasalt* globs missed.
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
  # nvidia|amd|intel|unknown — used to pre-seed the lib32-vulkan-driver
  # provider so pacman never shows the 13-way interactive menu.
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

preseed_lib32_driver() {
  # Install the matching lib32-vulkan-driver provider up front. Returns 0
  # when some provider is (now) installed, 1 when the user must choose.
  local prov=""
  case "$(detect_gpu_vendor)" in
    nvidia) prov="lib32-nvidia-utils" ;;
    amd) prov="lib32-vulkan-radeon" ;;
    intel) prov="lib32-vulkan-intel" ;;
  esac
  local p
  for p in lib32-nvidia-utils lib32-vulkan-radeon lib32-vulkan-intel lib32-vulkan-nouveau \
           lib32-vulkan-swrast lib32-vulkan-virtio lib32-vulkan-broadcom lib32-vulkan-freedreno \
           lib32-vulkan-panfrost lib32-vulkan-asahi lib32-vulkan-dzn lib32-vulkan-gfxstream \
           lib32-vulkan-powervr; do
    if pacman -Q "$p" >/dev/null 2>&1; then return 0; fi
  done
  if [ -n "$prov" ]; then
    echo "GPU detected: $(detect_gpu_vendor) — pre-installing $prov so pacman skips the provider menu."
    pacman_install "$prov" || return 1
    return 0
  fi
  return 1
}

detect_pm() {
  local id="unknown"
  [ -r /etc/os-release ] && id="$(grep -m1 '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
  case "$id" in
    arch|manjaro|endeavouros|cachyos|omarchy) echo "sudo pacman -S --needed" ;;
    debian|ubuntu|linuxmint|pop) echo "sudo apt install -y" ;;
    fedora|rhel|centos) echo "sudo dnf install -y" ;;
    *) echo "" ;;
  esac
}
PM="$(detect_pm)"

# tool -> "arch-pkg debian-pkg fedora-pkg" (dash = unavailable / manual)
DEPS="python3:python|python3|python3
jq:jq|jq|jq
git:git|git|git
zenity:zenity|zenity|zenity
gum:gum|-|-
mangohud:mangohud|mangohud|mangohud
vkcube:vulkan-tools|vulkan-tools|vulkan-tools
icoextract:icoextract|-|-"

install_pkg() {
  local tool="$1" arch_p="$2" deb_p="$3" fed_p="$4" pkg=""
  case "$PM" in
    *pacman*) pkg="$arch_p" ;;
    *apt*) pkg="$deb_p" ;;
    *dnf*) pkg="$fed_p" ;;
  esac
  if [ -z "$PM" ] || [ "$pkg" = "-" ] || [ -z "$pkg" ]; then
    echo "  manual install needed (see requirements.md)"
    return 1
  fi
  if confirm "install $tool ($PM $pkg)?"; then
    case "$PM" in
      *pacman*)
        # shellcheck disable=SC2086
        pacman_install $pkg
        ;;
      *)
        # shellcheck disable=SC2086
        $PM $pkg
        ;;
    esac
  else
    echo "  skipped $tool (some features may not work)"
    return 1
  fi
}

missing=0
while IFS=: read -r tool pkgs; do
  [ -z "$tool" ] && continue
  if command -v "$tool" >/dev/null 2>&1; then
    echo "ok: $tool"
    continue
  fi
  echo "missing: $tool"
  missing=1
  if [ "$CHECK_ONLY" = "0" ]; then
    arch_p="${pkgs%%|*}"; rest="${pkgs#*|}"; deb_p="${rest%%|*}"; fed_p="${rest##*|}"
    install_pkg "$tool" "$arch_p" "$deb_p" "$fed_p" || true
  fi
done <<EOF
$DEPS
EOF

# umu-launcher (Proton runner backend): official multilib package on Arch.
# The lib32-vulkan-driver provider menu (13 choices) would stall a fresh
# install, so pre-seed the matching provider based on detected GPU first.
if command -v umu-run >/dev/null 2>&1; then
  echo "ok: umu-run"
elif [ "$CHECK_ONLY" = "0" ] && [[ "$PM" == *pacman* ]] && pacman -Si umu-launcher >/dev/null 2>&1; then
  if confirm "install umu-launcher (Proton runner)?"; then
    if ! preseed_lib32_driver; then
      echo "  could not detect GPU — pacman may ask which lib32-vulkan-driver provider to use."
      echo "  NVIDIA: lib32-nvidia-utils | AMD: lib32-vulkan-radeon | Intel: lib32-vulkan-intel"
    fi
    pacman_install umu-launcher
  else
    echo "  skipped umu-launcher (proton runner will not work)"
  fi
else
  echo "note: umu-run not found (needed for the proton runner)."
  if [[ "$PM" == *pacman* ]]; then
    echo "  enable the multilib repo first: uncomment [multilib] in /etc/pacman.conf, then:"
    echo "  sudo pacman -Sy && sudo pacman -S --needed umu-launcher"
  else
    echo "  install umu-launcher from https://github.com/Open-Wine-Components/umu-launcher"
  fi
fi

# Proton-CachyOS (Proton runner backend): the verified build for 32-bit D3D
# titles (umu's default UMU-Proton misses those — the game process never
# creates a Vulkan instance there; see docs/limits.md). Fetched from the
# upstream release, verified by checksum, installed the way a manual Steam
# pickup works. x86_64_v3 asset on capable CPUs, generic x86_64 otherwise.
CACHYOS_PROTON_NAME="Proton-CachyOS Latest"
CACHYOS_PROTON_DIR="$HOME/.local/share/Steam/compatibilitytools.d/$CACHYOS_PROTON_NAME"
install_cachyos_proton() {
  for t in curl tar; do
    command -v "$t" >/dev/null 2>&1 || { echo "error: '$t' needed for this step" >&2; exit 1; }
  done
  local tag asset base
  tag="$(curl -sIL -o /dev/null -w '%{url_effective}' --max-time 30 \    https://github.com/CachyOS/proton-cachyos/releases/latest | sed 's|.*/tag/||')"
  [ -n "$tag" ] || { echo "error: could not resolve latest proton-cachyos release" >&2; exit 1; }
  echo "latest proton-cachyos: $tag"
  # NOTE: the tag already carries the "cachyos-" prefix, so the asset is
  # "proton-<tag>-...", NOT "proton-cachyos-<tag>-...".
  asset="proton-${tag}-x86_64.tar.xz"
  if grep -q avx2 /proc/cpuinfo 2>/dev/null && grep -q bmi2 /proc/cpuinfo 2>/dev/null; then
    asset="proton-${tag}-x86_64_v3.tar.xz"
  fi
  base="https://github.com/CachyOS/proton-cachyos/releases/download/${tag}"
  # Asset names drifted across releases before; fall back to scraping the
  # release page when the constructed URL 404s.
  if ! curl -sfI --max-time 30 -o /dev/null "$base/$asset"; then
    echo "  ($asset not found, resolving from release page...)"
    asset="$(curl -sL --max-time 30 \
      "https://github.com/CachyOS/proton-cachyos/releases/expanded_assets/${tag}" \
      | grep -oE "proton-cachyos[^\"' ]*x86_64(_v3)?\.tar\.xz" | sort -u | tail -n 1)"
    [ -n "$asset" ] || { echo "error: no x86_64 proton-cachyos asset for $tag" >&2; exit 1; }
  fi
  echo "downloading $asset (~1GB, one time)..."
  local tmp sha
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -L -C - --retry 5 --retry-all-errors --speed-limit 10240 --speed-time 30 \
    -o "$tmp/$asset" "$base/$asset" || { echo "error: download failed" >&2; exit 1; }
  [ -s "$tmp/$asset" ] || { echo "error: empty download" >&2; exit 1; }
  # Checksums are published as <asset-minus-.tar.xz>.sha512sum.
  sha="${asset%.tar.*}.sha512sum"
  if curl -sL --max-time 60 -o "$tmp/$sha" "$base/$sha"; then
    ( cd "$tmp" && sha512sum -c "$sha" ) \
      || { echo "error: checksum mismatch (redownload or check the release page)" >&2; exit 1; }
  else
    echo "  warning: no checksum published, skipping verification"
  fi
  tar -xf "$tmp/$asset" -C "$tmp" || { echo "error: extract failed" >&2; exit 1; }
  local src
  src="$(find "$tmp" -maxdepth 2 -name proton -type f | head -n 1)"
  [ -n "$src" ] || { echo "error: extracted tree has no proton entrypoint" >&2; exit 1; }
  src="$(dirname "$src")"
  mkdir -p "$(dirname "$CACHYOS_PROTON_DIR")"
  rm -rf "$CACHYOS_PROTON_DIR"
  mv "$src" "$CACHYOS_PROTON_DIR"
  rm -rf "$tmp"
  trap - EXIT
  unset tmp src tag asset base sha
  [ -x "$CACHYOS_PROTON_DIR/proton" ] || { echo "error: install landed wrong" >&2; exit 1; }
  echo "ok: $CACHYOS_PROTON_NAME installed."
}
seed_proton_default() {
  # Point the config default at the verified build, but never override
  # an existing user choice.
  python3 - "$HOME/.config/anime4k/config.json" <<'EOF'
import json, os, sys
p = sys.argv[1]
try:
    d = json.load(open(p))
    if not isinstance(d, dict):
        d = {}
except (OSError, ValueError):
    d = {}
if not d.get("proton"):
    d["proton"] = "Proton-CachyOS Latest"
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(d, open(p, "w"), indent=2)
    print("seeded config proton default: Proton-CachyOS Latest")
EOF
}
if [ -x "$CACHYOS_PROTON_DIR/proton" ]; then
  echo "ok: $CACHYOS_PROTON_NAME"
elif [ "$CHECK_ONLY" = "0" ]; then
  if confirm "install $CACHYOS_PROTON_NAME (verified Proton for 32-bit titles)?"; then
    install_cachyos_proton
    seed_proton_default
  else
    echo "  skipped (umu will fall back to UMU-Proton: 64-bit titles filter, 32-bit D3D may not)"
  fi
else
  echo "note: $CACHYOS_PROTON_NAME not found (recommended for 32-bit titles; see requirements.md)"
fi

# vkBasalt (the filter runtime): AUR, then automated source build, then pointer.
# Source builds track master: the last release tag predates current GCC and
# no longer compiles (missing <cstdint> includes); master is verified building.
VKBASALT_REPO="https://github.com/DadSchoorse/vkBasalt.git"
vkbasalt_found=0
if vkbasalt_layer_present; then vkbasalt_found=1; fi
vkbasalt_helper=""
command -v yay >/dev/null 2>&1 && vkbasalt_helper="yay"
[ -z "$vkbasalt_helper" ] && command -v paru >/dev/null 2>&1 && vkbasalt_helper="paru"
if [ "$vkbasalt_found" = "1" ]; then
  echo "ok: vkbasalt (system layer registered)"
elif [ "$CHECK_ONLY" = "0" ] && [ -n "$vkbasalt_helper" ] && "$vkbasalt_helper" -Si vkbasalt >/dev/null 2>&1; then
  if confirm "install vkbasalt from AUR ($vkbasalt_helper)?"; then
    "$vkbasalt_helper" -S --needed --noconfirm --answerclean None --answerdiff None vkbasalt \
      || echo "  AUR install failed — falling back to source build pointers below."
  else
    echo "  skipped vkbasalt (filtering will not work without it)"
  fi
fi
# Re-scan after any AUR attempt above (a fresh install may have landed).
vkbasalt_found=0
if vkbasalt_layer_present; then vkbasalt_found=1; fi
if [ "$vkbasalt_found" = "0" ] && [ "$CHECK_ONLY" = "0" ]; then
  echo "no system vkBasalt layer present."
  if confirm "build + install vkBasalt from source into ~/.local (no sudo needed for install)?"; then
    if [[ "$PM" == *pacman* ]]; then
      pacman_install meson ninja glslang spirv-headers vulkan-headers pkgconf gcc git \
        || { echo "error: build deps failed" >&2; exit 1; }
    else
      echo "  first install equivalents of: meson ninja glslang spirv-headers vulkan-headers pkgconf gcc git"
      echo "  (see requirements.md), then re-run with the layer present or answer yes."
    fi
    _vbdir="$(mktemp -d)"
    trap 'rm -rf "$_vbdir"' EXIT
    git clone --depth 1 --recurse-submodules "$VKBASALT_REPO" "$_vbdir/vkbasalt" \
      || { echo "error: clone failed" >&2; exit 1; }
    export PATH="$HOME/.local/bin:$PATH"
    meson setup "$_vbdir/vkbasalt/build" "$_vbdir/vkbasalt" --prefix="$HOME/.local" \
      || { echo "error: meson setup failed (missing build dep?)" >&2; exit 1; }
    ninja -C "$_vbdir/vkbasalt/build" || { echo "error: build failed" >&2; exit 1; }
    meson install -C "$_vbdir/vkbasalt/build" \
      || { echo "error: install failed" >&2; exit 1; }
    # Upstream installs a relative library_path, which the loader cannot
    # resolve outside ld paths: pin it to the absolute installed .so.
    _vklib="$HOME/.local/lib/libvkbasalt.so"
    _vkjson="$HOME/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
    [ -f "$_vklib" ] || { echo "error: expected $_vklib after install" >&2; exit 1; }
    if [ -f "$_vkjson" ]; then
      sed -i -e "s|\"library_path\": *\"[^\"]*\"|\"library_path\": \"$_vklib\"|" "$_vkjson"
    fi
    unset _vklib _vkjson
    rm -rf "$_vbdir"
    trap - EXIT
    unset _vbdir
    mkdir -p "$HOME/.local/share/vkBasalt"
    touch "$HOME/.local/share/vkBasalt/.anime4k-installed"
    mkdir -p "$HOME/.config/anime4k"
    config_set_key layer_dir "$HOME/.local/share/vulkan/implicit_layer.d"
    echo "ok: vkbasalt built + installed to ~/.local (layer_dir recorded in config.json)"
  else
    echo "  skipped — set layer_dir in ~/.config/anime4k/config.json to a local build instead."
  fi
fi
if [ "$vkbasalt_found" = "0" ] && [ "$CHECK_ONLY" = "1" ]; then
  echo "note: no system vkBasalt layer found (see install pointers above)."
fi

# rpgmaker-linux (RPGMaker runner backend): opt-in, fetched from upstream.
# Pinned to the validated release; override with RPGMAKER_VERSION=x.y.z
if command -v rpgmaker-linux >/dev/null 2>&1; then
  echo "ok: rpgmaker-linux ($(rpgmaker-linux --version 2>/dev/null | head -n 1))"
else
  echo "optional: rpgmaker-linux not found (needed for the rpgmaker runner)."
  if [ "$CHECK_ONLY" = "0" ] && confirm_no "install rpgmaker-linux support? (downloads NW.js runtimes, several hundred MB)"; then
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

# PySide6 (GUI only): system package preferred so desktop theming applies.
if [ -f "$ROOT/gui/app.py" ]; then
  if python3 -c "import PySide6" 2>/dev/null; then
    echo "ok: PySide6 (GUI)"
  elif [[ "$PM" == *pacman* ]]; then
    if confirm "install PySide6 (Qt GUI)?"; then
      pacman_install pyside6
    else
      echo "  skipped PySide6 (GUI will not start; TUI unaffected)"
    fi
  else
    echo "missing (GUI only): PySide6"
    echo "  install: pip install PySide6 (see requirements.md)"
  fi
fi

# (umu-launcher is handled above, next to the core deps, so its
# lib32 provider pre-seed runs before any other big transaction.)

if [ "$CHECK_ONLY" = "1" ]; then
  if [ "$missing" = "0" ]; then
    echo "all required tools present."
  else
    echo "missing tools (see above)."
    exit 1
  fi
  exit 0
fi

# Deploy shaders (only ours, by exact filename).
SHADER_DST="$HOME/.local/share/gamescope/reshade/Shaders"
mkdir -p "$SHADER_DST"
for f in "$ROOT"/shaders/Anime4K_Restore_*.fx; do
  cp "$f" "$SHADER_DST/"
done
echo "shaders deployed to $SHADER_DST"

# Config dir + seed config (never overwrite).
mkdir -p "$HOME/.config/anime4k"
if [ ! -f "$HOME/.config/anime4k/config.json" ]; then
  echo '{"_note":"optional overrides: prefix, proton, layer_dir, shader_dir"}' > "$HOME/.config/anime4k/config.json"
  echo "seeded ~/.config/anime4k/config.json (edit your defaults there)"
fi

# PATH symlinks (default on): anime4k TUI + GUI entry point.
if [ "$SYMLINK" = "1" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$ROOT/scripts/anime4k" "$HOME/.local/bin/anime4k"
  if [ -f "$ROOT/gui/app.py" ]; then
    ln -sf "$ROOT/gui/app.py" "$HOME/.local/bin/anime4k-gui"
    echo "symlinked: anime4k, anime4k-gui -> ~/.local/bin/"
  else
    echo "symlinked: anime4k -> ~/.local/bin/ (gui not built yet, skipping anime4k-gui)"
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
