# Requirements

Rows marked **[verified]** were tested on Arch/Omarchy. Others are best-effort
from upstream docs — confirmations welcome.

## Runtime (all runners)

| Need | Arch (verified) | Debian/Ubuntu | Fedora | Notes |
|---|---|---|---|---|
| python3 | `python` [verified] | `python3` | `python3` | JSON/config handling |
| jq | `jq` [verified] | `jq` | `jq` | TUI library |
| gum | AUR `charm-gum` or manual [verified via `gum`] | manual install | manual install | TUI only |
| zenity | `zenity` [verified] | `zenity` | `zenity` | file pickers |
| vkBasalt | AUR `vkbasalt`, else automated source build [verified: source build] | automated source build | automated source build | the filter runtime; `install.sh` handles both; verify with `anime4k doctor` |
| mangohud | `mangohud` [verified] | `mangohud` | `mangohud` | fps cap + overlay |
| vulkan-tools | `vulkan-tools` [verified] | `vulkan-tools` | `vulkan-tools` | optional: device list, `vkcube` test |
| icoextract | `icoextract` [verified] | manual (PyPI `icoextract`) | manual | game-icon extraction for the GUI |
| git | `git` [verified] | `git` | `git` | cloning this repo |

## Per-runner optionals

| Runner | Need | Notes |
|---|---|---|
| proton | `umu-launcher` (Arch multilib — installer handles it; enable multilib if missing; installer pre-installs the matching `lib32-vulkan-driver` provider from the detected GPU so pacman doesn't ask) or Faugus | provides `umu-run`; Steam Proton works too with adapted env |
| proton | Proton-CachyOS (verified for 32-bit D3D) — offered by `./install.sh` (upstream release tarball, checksum-verified; x86_64_v3 on capable CPUs) | install once via the installer; selected automatically as the config default (override per-launch with `--proton`; other builds like GE-Proton work too with adapted env) |
| rpgmaker | `rpgmaker-linux` — offered by `./install.sh` (pinned upstream release) or the [upstream install script](https://github.com/bakustarver/rpgmakermlinux-cicpoffs) |
| native | Mesa with Zink (Mesa ≥ 23) | for the GL→Vulkan translation path |

## Build-only (vkBasalt from source)

`meson ninja glslang spirv-headers vulkan-headers` (Arch names [verified];
Debian: `meson ninja-build glslang-tools spirv-headers libvulkan-dev`;
Fedora: `meson ninja-build glslang spirv-headers vulkan-headers`).

## GUI (PySide6 + Qt Quick)

The launcher GUI and the translation textbox are both Qt Quick (QML). Prefer
the system package so the app follows desktop/Qt theming (qt6ct etc.):

| Distro | Install |
|---|---|
| Arch | `sudo pacman -S pyside6` [verified] |
| Others | `pip install PySide6` (bundled Qt) |

QML modules needed: `QtQuick`, `QtQuick.Controls`, `QtQuick.Layouts`
(screens), `QtQuick.Dialogs` (file/font/color pickers) and `QtQuick.Effects`
(text shadow). On Arch these ship in `qt6-declarative` [verified: 6.11.2]
(pulled in with the desktop Qt stack; `pip install PySide6` bundles them).

The GUI follows the active **Omarchy** color scheme when present, else the
desktop dark/light preference; override in Settings. `anime4k-gui --diagnose`
prints the resolved theme and verifies the QML context, and
`--self-test` loads the whole UI headlessly (see README).

## VN translation (translate/)

Fetched at install time (pinned + checksum-verified, never committed):

| Need | Arch (verified) | Debian/Ubuntu | Fedora | Notes |
|---|---|---|---|---|
| python-websocket-client | `python-websocket-client` [verified] | `python3-websocket` | `python3-websocket-client` | hook bridge client; installer handles it |
| python-requests | `python-requests` [verified] | `python3-requests` | `python-requests` | DeepL browser automation; installer handles it |
| Textractor + bridge | fetched by `translate/fetch-vendor.sh` | same | same | Chenx221 build + kuroahna bridge (or hardened fork asset) |
| Chromium browser (any) | auto-detected [verified: default-browser-first + CDP smoke test] | same | same | Brave/Chromium/Chrome/Edge/Vivaldi/Opera; default browser preferred, isolated debug profile always; installer records the pick in `translate/config.json` |
| DLX server (opt-in) | fetched by installer | same | same | local DeepL fallback on :1188 |
