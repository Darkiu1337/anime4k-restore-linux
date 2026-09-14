#!/bin/bash
# uninstall.sh — remove what install.sh deployed. Never touches your game
# library (~/.config/anime4k/games.json) or config.json.
# Usage: ./uninstall.sh
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHADER_DST="$HOME/.local/share/gamescope/reshade/Shaders"
removed=0
kept=0
for v in S M L Soft_S Soft_L; do
  dst="$SHADER_DST/Anime4K_Restore_$v.fx"
  src="$ROOT/shaders/Anime4K_Restore_$v.fx"
  if [ -f "$dst" ]; then
    if [ -f "$src" ] && cmp -s "$dst" "$src"; then
      rm -f "$dst"
      removed=1
    else
      echo "kept $dst (differs from this repo copy; remove by hand if unwanted)"
      kept=1
    fi
  fi
done
[ "$removed" = "1" ] && echo "removed deployed shaders."
[ "$kept" = "1" ] && echo "(some shader files were kept, see above.)"
for link in "$HOME/.local/bin/anime4k" "$HOME/.local/bin/anime4k-gui"; do
  if [ -L "$link" ]; then
    rm -f "$link"
    echo "removed symlink $link"
  fi
done
for desk in anime4k.desktop anime4k-gui.desktop; do
  if [ -f "$HOME/.local/share/applications/$desk" ]; then
    rm -f "$HOME/.local/share/applications/$desk"
    echo "removed desktop entry $desk"
  fi
done
rm -f "$HOME/.config/anime4k"/vkbasalt-*.conf
if [ -f "$HOME/.local/share/vkBasalt/.anime4k-installed" ]; then
  rm -f "$HOME/.local/share/vkBasalt/.anime4k-installed"
  rm -f "$HOME/.local/lib/libvkbasalt.so" "$HOME/.local/lib64/libvkbasalt.so"
  rm -f "$HOME/.local/share/vulkan/implicit_layer.d/vkBasalt.json"
  rmdir "$HOME/.local/share/vkBasalt" 2>/dev/null || true
  echo "removed source-built vkBasalt (system packages it pulled in are left alone)."
fi
echo "done. Kept (your data): ~/.config/anime4k/games.json and config.json."
echo "System packages are never removed. Delete the repo directory itself to finish: $ROOT"
