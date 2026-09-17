#!/bin/bash
# anime4k-lib.sh — shared core for the Anime4K Restore launchers.
# Source it:  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#             source "$SCRIPT_DIR/anime4k-lib.sh"
# Not meant to be executed directly.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "anime4k-lib.sh is a library, source it instead of running it." >&2
  exit 1
fi

_ANIME4K_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANIME4K_ROOT="$(cd "$_ANIME4K_LIB_DIR/.." && pwd)"
unset _ANIME4K_LIB_DIR

# User config (~/.config/anime4k/config.json, optional). Keys: prefix, proton,
# layer_dir, shader_dir, wow64. Missing file/keys fall back to builtins below.
ANIME4K_CONFIG="$HOME/.config/anime4k/config.json"
ak_config_get() {
  python3 -c "import json,sys; print(json.load(open('$ANIME4K_CONFIG')).get('$1', '$2'))" 2>/dev/null || printf '%s' "$2"
}

# Shader dir: explicit env wins, then deployed XDG dir, then repo copy (dev).
_ANIME4K_XDG_SHADERS="$HOME/.local/share/gamescope/reshade/Shaders"
if [ -n "${ANIME4K_SHADER_DIR:-}" ]; then
  : # kept as-is
elif [ -d "$_ANIME4K_XDG_SHADERS" ]; then
  ANIME4K_SHADER_DIR="$_ANIME4K_XDG_SHADERS"
else
  ANIME4K_SHADER_DIR="$ANIME4K_ROOT/shaders"
fi
unset _ANIME4K_XDG_SHADERS

ak_die() { echo "error: $*" >&2; exit 1; }
ak_log() { echo "anime4k: $*" >&2; }

ak_need() {
  command -v "$1" >/dev/null 2>&1 || ak_die "required tool '$1' not found on PATH"
}

# Locale handling for the game. HOST_LC_ALL is the pressure-vessel host-locale
# hint: forcing a locale the host has not generated makes some engines
# (Emote/.NET, e.g. mlove) exit in ~1s, while LANG alone is tolerated
# (docs/limits.md). So HOST_LC_ALL is only exported for a locale the host can
# actually provide; otherwise the caller is warned to generate it.
ak_locale_available() {
  local loc="$1" want
  [ -n "$loc" ] || return 1
  command -v locale >/dev/null 2>&1 || return 1
  want="$(printf '%s' "$loc" | tr 'A-Z' 'a-z' | sed 's/\.utf-8$/.utf8/')"
  locale -a 2>/dev/null | tr 'A-Z' 'a-z' | grep -qxF "$want"
}

ak_locale_env() {
  local loc="$1"
  [ -n "$loc" ] || return 0
  export LANG="$loc"
  if [ -n "${ANIME4K_NO_HOST_LC_ALL:-}" ]; then
    unset HOST_LC_ALL
    return 0
  fi
  if ak_locale_available "$loc"; then
    export HOST_LC_ALL="$loc"
  else
    unset HOST_LC_ALL
    ak_log "warning: locale $loc is not generated on this system; leaving HOST_LC_ALL unset so the game can start. To force the locale, add '$loc UTF-8' to /etc/locale.gen and run: sudo locale-gen"
  fi
}

# New WoW64 (default): run 32-bit Windows PE inside the single 64-bit host
# process, so Wine forwards its Vulkan calls to the 64-bit loader and the
# 64-bit vkBasalt hooks 32-bit D3D9 too. Requires a 64-bit prefix; a legacy
# win32 prefix (new WoW64-unsupported) keeps old WoW64. Opt out with
# `wow64=0` / --no-wow64. Why: docs/limits.md.
# Resolve the configured `proton` value to an absolute Proton directory:
# accepts a path or a bare build name (searched in the common
# compatibilitytools.d dirs). Prints the path, or nothing (return 1) when it
# cannot be resolved — callers then fall back to the umu-managed UMU-Proton.
ak_proton_resolve() {
  local p="$1" d
  [ -n "$p" ] || return 1
  if [ -d "$p" ] && { [ -x "$p/proton" ] || [ -x "$p/proton.sh" ]; }; then
    printf '%s' "$p"
    return 0
  fi
  for d in "$HOME/.local/share/Steam/compatibilitytools.d" \
           "$HOME/.steam/steam/compatibilitytools.d" \
           "$HOME/.steam/root/compatibilitytools.d" \
           "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d" \
           "/usr/share/steam/compatibilitytools.d" \
           "/usr/local/share/steam/compatibilitytools.d"; do
    [ -d "$d/$p" ] || continue
    if [ -x "$d/$p/proton" ] || [ -x "$d/$p/proton.sh" ]; then
      printf '%s' "$d/$p"
      return 0
    fi
  done
  return 1
}

# True when a Proton build can run 32-bit PE through new WoW64. An explicit
# value that isn't a local dir is NOT assumed capable: the runner resolves the
# path first and otherwise falls back to umu-managed (docs/limits.md).
ak_proton_wow64_capable() {
  local p="$1"
  [ -n "$p" ] || return 0
  [ -d "$p" ] || return 1
  [ -x "$p/files/bin-wow64/wine" ] && return 0
  grep -qa 'PROTON_USE_WOW64' "$p/proton" 2>/dev/null && return 0
  # A 64-bit-only build (no wine64 loader) always runs new WoW64.
  [ -e "$p/files/bin/wine" ] && [ ! -e "$p/files/bin/wine64" ] && return 0
  return 1
}

ak_wow64_env() {
  local prefix="$1" want="${2:-1}"
  if [ "$want" != "1" ]; then
    ak_log "wow64: off (old WoW64 — 32-bit titles need a 32-bit vkBasalt)"
    return 0
  fi
  if [ -f "$prefix/system.reg" ] && grep -qa '#arch=win32' "$prefix/system.reg"; then
    ak_log "wow64: prefix is win32 — using old WoW64 (new WoW64 needs a 64-bit prefix)"
    return 0
  fi
  export WINEARCH=wow64
  export PROTON_USE_WOW64=1
  ak_log "wow64: on (32-bit titles route through the 64-bit Vulkan loader)"
}

# Kill leftover processes of a previous run of the SAME game (best effort).
# The token is matched against full command lines; the first character is
# bracketed so pkill can never match our own command line. Own PID and
# parent are always spared. Never fails (missing pgrep/pkill included).
# Example: ak_kill_strays "Spooky Milk Life" ; ak_kill_strays "nw --ozone-platform"
ak_kill_strays() {
  local token="$1" pat pids pid
  [ -n "$token" ] || return 0
  command -v pgrep >/dev/null 2>&1 || return 0
  pat="[${token:0:1}]${token:1}"
  pids="$(pgrep -f "$pat" 2>/dev/null || true)"
  [ -z "$pids" ] && return 0
  for pid in $pids; do
    [ "$pid" = "$$" ] && continue
    [ "$pid" = "$PPID" ] && continue
    kill -TERM "$pid" 2>/dev/null || true
  done
  sleep 2
  for pid in $pids; do
    [ "$pid" = "$$" ] && continue
    [ "$pid" = "$PPID" ] && continue
    if kill -0 "$pid" 2>/dev/null; then
      ak_log "cleaned stray processes matching '$token'"
      kill -KILL "$pid" 2>/dev/null || true
    fi
  done
  return 0
}

# Locate the vkBasalt layer manifest in effect: explicit layer_dir first,
# then the system implicit-layer dirs (case-insensitive: the source build
# installs vkBasalt.json, which exact-case globs miss). Prints the path,
# or nothing when no layer is registered.
ak_vkbasalt_manifest() {
  local dir d hit
  dir="$(ak_config_get layer_dir "")"
  if [ -n "$dir" ] && [ -f "$dir/vkBasalt.json" ]; then
    printf '%s' "$dir/vkBasalt.json"
    return 0
  fi
  for d in "$HOME/.config/vulkan/implicit_layer.d" "$HOME/.local/share/vulkan/implicit_layer.d" \
           /usr/local/share/vulkan/implicit_layer.d /usr/share/vulkan/implicit_layer.d; do
    [ -d "$d" ] || continue
    hit="$(find "$d" -maxdepth 1 -iname '*vkbasalt*.json' -print -quit 2>/dev/null)"
    if [ -n "$hit" ]; then
      printf '%s' "$hit"
      return 0
    fi
  done
  return 1
}

# Resolve a layer manifest's library_path to an existing file: absolute
# paths directly, bare filenames via ldconfig + standard lib dirs.
# Prints the path, or nothing when the registration is broken.
ak_vkbasalt_lib() {
  local manifest="$1" lib p d
  [ -f "$manifest" ] || return 1
  lib="$(python3 - "$manifest" <<'EOF'
import json, sys
print(json.load(open(sys.argv[1]))["layer"]["library_path"])
EOF
)" 2>/dev/null || return 1
  case "$lib" in
    /*)
      [ -f "$lib" ] && printf '%s' "$lib" && return 0
      return 1
      ;;
    *)
      p="$(ldconfig -p 2>/dev/null | awk -v L="$lib" '$1 == L { print $NF; exit }')"
      if [ -n "$p" ] && [ -f "$p" ]; then
        printf '%s' "$p"
        return 0
      fi
      for d in /usr/lib /usr/lib64 "$HOME/.local/lib" "$HOME/.local/lib64"; do
        if [ -f "$d/$lib" ]; then
          printf '%s' "$d/$lib"
          return 0
        fi
      done
      return 1
      ;;
  esac
}

# Print a DXVK device-name substring for the discrete GPU (NVIDIA preferred),
# or nothing when none is detectable (caller then leaves DXVK unfiltered).
# vulkaninfo deviceType picks real discrete GPUs; the ICD fallback only
# yields vendor substrings, which is all DXVK_FILTER_DEVICE_NAME needs.
ak_discrete_gpu_name() {
  if command -v vulkaninfo >/dev/null 2>&1; then
    local pick
    pick="$(vulkaninfo --summary 2>/dev/null | python3 -c '
import re, sys
gpus, cur = [], {}
for line in sys.stdin:
    s = line.strip()
    if re.match(r"^(GPU\d+:|GPU id)", s):
        if cur:
            gpus.append(cur)
        cur = {}
    elif s.startswith("deviceName"):
        if "name" in cur:
            gpus.append(cur)
            cur = {}
        cur["name"] = s.split("=", 1)[1].strip()
    elif s.startswith("deviceType"):
        t = s.split("=", 1)[1].strip()
        cur["type"] = t.split("PHYSICAL_DEVICE_TYPE_")[-1]
if cur:
    gpus.append(cur)
disc = [g["name"] for g in gpus if g.get("type") == "DISCRETE_GPU" and g.get("name")]
nvidia = [n for n in disc if "NVIDIA" in n]
print((nvidia or disc or [""])[0])
')" 2>/dev/null
    if [ -n "$pick" ]; then
      printf '%s' "$pick"
      return 0
    fi
  fi
  if ls /usr/share/vulkan/icd.d/nvidia_icd*.json >/dev/null 2>&1; then
    printf 'NVIDIA'
    return 0
  fi
  if ls /usr/share/vulkan/icd.d/radeon_icd*.json /usr/share/vulkan/icd.d/amd_icd*.json >/dev/null 2>&1; then
    printf 'AMD'
    return 0
  fi
  return 1
}

# Validate Restore variant (S, M, L, Soft_S, Soft_L).
ak_variant() {
  case "${1:-L}" in
    S|M|L|Soft_S|Soft_L) printf '%s' "$1" ;;
    *) ak_die "unknown variant '$1' (expected S, M, L, Soft_S or Soft_L)" ;;
  esac
}

# Set up vkBasalt layer env for the given variant.
# Structural off switch: with DISABLE_VKBASALT=1 set, export nothing and
# scrub any inherited layer variables, so the loader never sees vkBasalt.
# (Relying on the loader's disable flag is unreliable for explicitly-listed
# layers, which is how uninstalled builds are loaded.)
ak_vkbasalt_env() {
  if [ -n "${DISABLE_VKBASALT:-}" ]; then
    unset VK_ADD_LAYER_PATH VK_INSTANCE_LAYERS ENABLE_VKBASALT VKBASALT_CONFIG_FILE
    return 0
  fi
  local variant="$1"
  local shader="$ANIME4K_SHADER_DIR/Anime4K_Restore_${variant}.fx"
  [ -f "$shader" ] || ak_die "shader missing: $shader"
  local confdir="$HOME/.config/anime4k"
  mkdir -p "$confdir"
  local conf="$confdir/vkbasalt-${variant}.conf"
  sed -e "s|@SHADER_DIR@|$(dirname "$shader")|g" -e "s|@VARIANT@|$variant|g" \
    "$ANIME4K_ROOT/shaders/vkbasalt.conf.in" > "$conf"
  local layer_dir
  layer_dir="$(ak_config_get layer_dir "")"
  local manifest lib
  manifest="$(ak_vkbasalt_manifest)" \
    || ak_die "no vkBasalt layer found (set layer_dir in $ANIME4K_CONFIG or install vkbasalt; see requirements.md)"
  lib="$(ak_vkbasalt_lib "$manifest")" \
    || ak_die "vkBasalt layer registered at $manifest but its library is missing (reinstall vkbasalt; run: anime4k doctor)"
  if [ -n "$layer_dir" ] && [ "$manifest" = "$layer_dir/vkBasalt.json" ]; then
    export VK_ADD_LAYER_PATH="$layer_dir"
    export VK_INSTANCE_LAYERS="VK_LAYER_VKBASALT_post_processing"
  else
    unset VK_ADD_LAYER_PATH VK_INSTANCE_LAYERS
  fi
  export ENABLE_VKBASALT=1
  export VKBASALT_CONFIG_FILE="$conf"
}

# Resolve the rpgmaker-linux wrapper's shared NW.js manifest (honors the
# wrapper's custom-path file, then its default location).
ak_rpgmaker_template() {
  local mainfd=""
  if [ -r "$HOME/.config/defrpgmakerlinuxpath.txt" ]; then
    mainfd="$(head -n 1 "$HOME/.config/defrpgmakerlinuxpath.txt")"
    mainfd="${mainfd%/}"
  fi
  [ -n "$mainfd" ] || mainfd="$HOME/desktopapps"
  local tpl="$mainfd/nwjs/nwjs/packagefiles/package.json"
  [ -f "$tpl" ] || ak_die "rpgmaker-linux manifest not found at $tpl (is rpgmaker-linux installed?)"
  printf '%s' "$tpl"
}

# Pick a file via zenity when no path was given (empty string = cancelled).
# $2 (optional): file-filter string, e.g. 'Windows executables | *.exe *.EXE'.
# Empty/missing $2 means no filter (all files selectable).
ak_pick_file() {
  local title="$1" pattern="$2"
  ak_need zenity
  if [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    ak_die "no display for file picker; pass the path as an argument instead"
  fi
  if [ -n "$pattern" ]; then
    zenity --file-selection --title="$title" --file-filter="$pattern" 2>/dev/null || true
  else
    zenity --file-selection --title="$title" 2>/dev/null || true
  fi
}

# Pick a directory via zenity when none was given (empty string = cancelled).
ak_pick_dir() {
  local title="$1"
  ak_need zenity
  if [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    ak_die "no display for folder picker; pass --gamepath instead"
  fi
  zenity --file-selection --directory --title="$title" 2>/dev/null || true
}

# Wrapper-template patch/restore (shared NW.js manifest used by rpgmaker-linux).
# The template location honors the wrapper's own custom-path file, then default.
ANIME4K_TEMPLATE=""
ANIME4K_TEMPLATE_BACKUP="/tmp/rpg-template-package.json.bak-anime4k"

ak_template_path() {
  if [ -z "$ANIME4K_TEMPLATE" ]; then
    ANIME4K_TEMPLATE="$(ak_rpgmaker_template)"
  fi
  printf '%s' "$ANIME4K_TEMPLATE"
}

ak_template_patch() {
  local tpl
  tpl="$(ak_template_path)"
  ak_need python3
  cp "$tpl" "$ANIME4K_TEMPLATE_BACKUP"
  python3 - "$tpl" <<'EOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
extra = " --use-gl=angle --use-angle=vulkan --disable-gpu-sandbox --ignore-gpu-blocklist --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan"
if "--use-angle=vulkan" not in d.get("chromium-args", ""):
    d["chromium-args"] = d.get("chromium-args", "") + extra
json.dump(d, open(p, "w"), indent=2)
EOF
}

ak_template_restore() {
  if [ -f "$ANIME4K_TEMPLATE_BACKUP" ]; then
    local tpl
    tpl="$(ak_template_path)"
    cp "$ANIME4K_TEMPLATE_BACKUP" "$tpl"
    rm -f "$ANIME4K_TEMPLATE_BACKUP"
  fi
}

# MangoHud fps limit (+optional overlay) for runners without a DXVK cap.
# FPS: number or off. HUD: 1 = show overlay, 0 = limit silently (no_display).
ak_mangohud_env() {
  local fps="${1:-60}" hud="${2:-0}"
  if [ "$fps" = "off" ] && [ "$hud" = "0" ]; then
    return 0
  fi
  local cfg=""
  if [ "$fps" != "off" ]; then
    [[ "$fps" =~ ^[0-9]+$ ]] || ak_die "--fps needs a number or off"
    cfg="fps_limit=$fps"
  fi
  if [ "$hud" = "0" ]; then
    cfg="${cfg:+,}no_display"
  fi
  cfg="${cfg#,}"
  export MANGOHUD=1
  export MANGOHUD_CONFIG="$cfg"
}

# Zink (OpenGL-on-Vulkan) env so vkBasalt can hook GL-only games.
# GPU select: nvidia (GTX 1650) | amd (iGPU) | auto (loader default).
ak_zink_env() {
  case "${1:-nvidia}" in
    nvidia) export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json ;;
    amd) export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json ;;
    auto) unset VK_ICD_FILENAMES ;;
    *) ak_die "unknown GPU '$1' (expected nvidia, amd or auto)" ;;
  esac
  export __GLX_VENDOR_LIBRARY_NAME=mesa
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
}

# Helper .exe names that are never the game itself (launchers, crash
# handlers, redist installers). Used by engine detection and exe picking.
ak_helper_exe() {
  case "$(basename "$1" | tr '[:upper:]' '[:lower:]')" in
    unitycrashhandler*|notification_helper*|nwjc*|payload*|*uninstall*|\
    vcredist*|dxsetup*|dotnetfx*|crashpad_handler*|crash_reporter*|*setup*)
      return 0 ;;
  esac
  return 1
}

# Pick the main executable from a game dir: Game.exe, then <dirname>.exe,
# then the single remaining non-helper exe. Prints path or nothing.
ak_main_exe() {
  local dir="$1" f base
  for f in "$dir"/Game.exe "$dir"/GAME.EXE; do
    [ -f "$f" ] && { printf '%s' "$f"; return 0; }
  done
  base="$(basename "$dir")"
  for f in "$dir/$base.exe" "$dir/$base.EXE"; do
    [ -f "$f" ] && { printf '%s' "$f"; return 0; }
  done
  local cands="" n=0
  for f in "$dir"/*.exe "$dir"/*.EXE; do
    [ -f "$f" ] || continue
    ak_helper_exe "$f" && continue
    cands="$f"; n=$((n + 1))
  done
  [ "$n" = "1" ] && printf '%s' "$cands"
  return 0
}

# Game/engine detection. Prints: engine|runner|confidence|root|detail
# Engines: rpgmaker-mv, rpgmaker-xp (covers VX/VXAce), renpy-native,
#   renpy-windows, unity-windows, unity-linux, godot, electron, tyrano,
#   appimage, exe (generic Windows), elf (generic native), unknown.
# Runners: proton, rpgmaker, native, ask.
# Confidence: high, medium, low. Never fails (unknown is a valid outcome).
ak_detect_engine() {
  local target="$1" dir base
  if [ -f "$target" ]; then
    dir="$(dirname "$target")"
  elif [ -d "$target" ]; then
    dir="$target"
  else
    printf 'unknown|ask|low|%s|no such path' "$target"
    return 0
  fi
  base="$(basename "$dir")"

  # RPGMaker MV/MZ (game root or www/ depth, normalized upward).
  if [ -f "$dir/www/index.html" ] && [ -f "$dir/www/js/rpg_core.js" ]; then
    printf 'rpgmaker-mv|rpgmaker|high|%s|RPGMaker MV/MZ markers' "$dir"
    return 0
  fi
  if [ -f "$dir/index.html" ] && [ -f "$dir/js/rpg_core.js" ]; then
    printf 'rpgmaker-mv|rpgmaker|high|%s|RPGMaker MV/MZ markers (www/ depth)' "$(dirname "$dir")"
    return 0
  fi

  # RPGMaker XP/VX/VXAce (RGSS data + ini).
  if ls "$dir"/Data/*.rxdata >/dev/null 2>&1 || ls "$dir"/Data/*.rvdata >/dev/null 2>&1 || \
     ls "$dir"/Data/*.rvdata2 >/dev/null 2>&1; then
    if [ -f "$dir/Game.ini" ]; then
      printf 'rpgmaker-xp|proton|high|%s|RGSS data + Game.ini (runs best under Proton)' "$dir"
    else
      printf 'rpgmaker-xp|proton|medium|%s|RGSS data without Game.ini' "$dir"
    fi
    return 0
  fi

  # Ren'Py (engine dirs decide native vs Windows).
  if [ -d "$dir/renpy" ] && [ -d "$dir/game" ]; then
    local sh launcher=""
    for sh in "$dir"/*.sh; do
      [ -f "$sh" ] && [ -x "$sh" ] && { launcher="$sh"; break; }
    done
    if [ -n "$launcher" ]; then
      printf 'renpy-native|native|high|%s|RenPy distro with Linux launcher' "$dir"
      return 0
    fi
    local exe
    exe="$(ak_main_exe "$dir")"
    if [ -n "$exe" ]; then
      printf 'renpy-windows|proton|high|%s|RenPy Windows build (ANGLE-forced under Proton)' "$dir"
      return 0
    fi
    printf 'renpy-unknown|ask|low|%s|RenPy layout, no runnable found' "$dir"
    return 0
  fi

  # Unity (Data dir + runtime markers; .dll = Windows, .so = Linux).
  local data
  data="$(find "$dir" -maxdepth 1 -type d -name '*_Data' | head -n 1)"
  if [ -n "$data" ]; then
    if [ -f "$data/../GameAssembly.dll" ] || [ -f "$data/../GameAssembly.so" ] || \
       [ -d "$data/../MonoBleedingEdge" ]; then
      local exe
      exe="$(ak_main_exe "$dir")"
      if [ -n "$exe" ]; then
        printf 'unity-windows|proton|high|%s|Unity IL2CPP/Mono bundle' "$dir"
        return 0
      fi
    fi
    local elf
    elf="$(find "$dir" -maxdepth 1 -type f \( -iname '*.x86_64' -o -iname '*.x86' \) | head -n 1)"
    if [ -z "$elf" ]; then
      for f in "$dir"/*; do
        if [ -f "$f" ] && [ -x "$f" ] && [ "${f##*.}" = "$f" ]; then elf="$f"; break; fi
      done
    fi
    if [ -n "$elf" ]; then
      printf 'unity-linux|native|high|%s|Unity Linux bundle' "$dir"
      return 0
    fi
  fi

  # Godot (.pck + engine binary).
  if ls "$dir"/*.pck >/dev/null 2>&1; then
    local exe
    exe="$(ak_main_exe "$dir")"
    if [ -n "$exe" ]; then
      printf 'godot-windows|proton|medium|%s|Godot .pck + Windows exe' "$dir"
      return 0
    fi
    printf 'godot|ask|low|%s|Godot data without a clear launcher' "$dir"
    return 0
  fi

  # Electron / Chromium-app bundles.
  if [ -d "$dir/resources" ] && ls "$dir"/resources/*.asar >/dev/null 2>&1; then
    printf 'electron|proton|medium|%s|Electron bundle (filter support experimental)' "$dir"
    return 0
  fi

  # KiriKiri visual novels (data.xp3 archives + Windows exe, DirectX-based).
  if [ -f "$dir/data.xp3" ]; then
    local kexe
    kexe="$(ak_main_exe "$dir")"
    if [ -n "$kexe" ]; then
      printf 'kirikiri|proton|high|%s|KiriKiri bundle (DirectX, hookable)' "$dir"
      return 0
    fi
  fi

  # TyranoBuilder / web exports handled by the rpgmaker wrapper.
  if [ -d "$dir/tyrano" ] && [ -d "$dir/data" ] && [ -f "$dir/index.html" ]; then
    printf 'tyrano|rpgmaker|medium|%s|TyranoScript layout (filter unlikely)' "$dir"
    return 0
  fi

  # AppImage.
  local appimg
  appimg="$(find "$dir" -maxdepth 1 -name '*.AppImage' 2>/dev/null | head -n 1)"
  if [ -n "$appimg" ]; then
    printf 'appimage|native|high|%s|AppImage bundle' "$dir"
    return 0
  fi

  # Fallbacks by launcher kind.
  if [ -f "$target" ]; then
    case "$target" in
      *.exe|*.EXE)
        printf 'exe|proton|low|%s|unrecognized Windows executable' "$dir"
        return 0
        ;;
    esac
    if [ -x "$target" ]; then
      printf 'elf|native|low|%s|unrecognized native executable' "$dir"
      return 0
    fi
  fi
  local exe
  exe="$(ak_main_exe "$dir")"
  if [ -n "$exe" ]; then
    printf 'exe|proton|low|%s|unrecognized dir with Windows executable' "$dir"
    return 0
  fi
  printf 'unknown|ask|low|%s|no recognizable game markers' "$dir"
  return 0
}
