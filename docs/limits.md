# Limits

What the filter can and cannot touch. The rule of thumb: **vkBasalt must see
a Vulkan swapchain**. Everything below follows from that.

## Per runner

### proton (Windows games)
| API | Filter? | Notes |
|---|---|---|
| D3D9 / 10 / 11 (DXVK) | yes | the common case, verified (incl. 32-bit exes: Wine routes their Vulkan calls through its 64-bit loader, so the 64-bit layer still hooks them — but see the Proton note below) |
| D3D12 (VKD3D-Proton) | yes | same mechanism, verified compatible |
| Native Vulkan | yes | passes straight through |
| OpenGL (wined3d) / software / very old titles | no | game launches unfiltered, no error — if a title that filters on one machine doesn't on another, compare `PROTON_LOG=1` renderer lines and the DXVK device (`--dry-run` shows it) |
| 32-bit executables | depends on the Proton build | Proton-CachyOS hooks 32-bit D3D9 (verified: 32-bit KiriKiri, 4 vkBasalt init blocks); UMU-Proton-10.0-4 was observed NOT hooking the same title (1 block — game process never creates a Vulkan instance) while 64-bit titles hook fine under both. If a 32-bit title stays unfiltered, pin a working Proton via `--proton` or the config `proton` default |
| 32-bit native Linux binaries (not Proton) | no | our vkBasalt build is 64-bit only |

Ren'Py Windows builds are auto-switched to the ANGLE (DirectX) renderer so
they land on DXVK; override with `RENPY_RENDERER` if you know better.

### rpgmaker (RPGMaker game folders)
| Engine | Filter? | Notes |
|---|---|---|
| MV / MZ (Chromium) | yes | temp Vulkan-flag patch, restored on exit; X11 ozone |
| XP / VX / VXAce, Tyrano, Godot, other | no | script prints the Proton equivalent and launches unfiltered |

### native (Linux executables)
| Case | Filter? | Notes |
|---|---|---|
| Native Vulkan, 64-bit | yes | direct hook |
| OpenGL, 64-bit | yes, via Zink translation | set automatically; `--gl auto` bypasses |
| 32-bit anything | no | vkBasalt build limitation |
| Software-rendered (llvmpipe/SWDraw) | no | nothing for the filter to accelerate |

## GPU selection

The filter runs **where the game renders** (vkBasalt lives inside the game
process), so the GPU picker moves game and filter together — there is no
separate filter device. Pick per game based on where you want the heat.

Defaults: the proton runner auto-selects the discrete GPU when one is
detectable (`--dry-run` prints the choice; `--dxvk-device auto` forces the
loader default, an explicit name overrides). The rpgmaker/native runners
take `--gpu nvidia|amd|auto`. (An early theory blamed the default adapter
for a missed filter — that case turned out to be the Proton build — but
pinning game+filter to the strong GPU remains the sane default.)

Run `anime4k doctor` on a new machine to verify the whole chain
(manifest, library, shaders, backends, live vkcube run) without any game.

## Display servers and compositors

Verified on Hyprland/Wayland (AMD iGPU + NVIDIA dGPU, single 1080p output).
XWayland versus native Wayland makes no difference to the filter. Gamescope's
`--reshade-effect` path segfaults on the reference machine (stock builds too),
so compositing tricks are out; everything here is in-process filtering.

## Variants

| Variant | Passes | Relative cost | Live status |
|---|---|---|---|
| S | 4 (3 conv + output) | 1× (baseline) | played, 100fps class |
| M | 7 (6 conv + dense output) | ~2× S | played, no errors |
| L | 9 (split dual convs + output) | ~4× S | played, 60fps capped |
| Soft_S | 4, soft-line tuned | ~1× S | played, no errors |
| Soft_L | 9-way split, soft-line tuned | ~4× S | played, no errors |

Soft variants target aliased/downscaled art rather than compression blur.
Cost scales with input pixels; all figures at 1080p on a GTX 1650-class GPU.

## Game detection (`anime4k detect <path>`)

Marker-based engine sniffing, shared by the TUI, GUI and the rpgmaker
runner. High confidence auto-fills the runner (confirmed on save);
anything else asks with the suggestion pre-selected.

| Markers | Engine | Runner |
|---|---|---|
| `www/index.html` + `www/js/rpg_core.js` (root or `www/` depth) | rpgmaker-mv | rpgmaker |
| `Data/*.rxdata` / `*.rvdata*` + `Game.ini` | rpgmaker-xp | proton |
| `renpy/` + `game/` + Linux launcher (`.sh`/ELF) | renpy-native | native |
| `renpy/` + `game/` + `.exe`, no `.sh` | renpy-windows | proton |
| `*_Data/` + `GameAssembly.dll`/`MonoBleedingEdge` + `.exe` | unity-windows | proton |
| `*_Data/` + `GameAssembly.so` + ELF launcher | unity-linux | native |
| `*.pck` + exe / ELF | godot | proton / native |
| `resources/*.asar` + `.exe` | electron | proton (experimental) |
| `tyrano/` + `data/` + `index.html` | tyrano | rpgmaker (filter unlikely) |
| `*.AppImage` | appimage | native |
| lone `.exe` / ELF / nothing recognizable | exe / elf / unknown | proton / native / ask |

Helper executables (`UnityCrashHandler*`, `nwjc*`, `payload*`,
uninstallers, redist installers…) are never mistaken for the game.

## Game language (`--lang`, Proton/native)

Some titles (notably Japanese VNs) only run correctly under their native
locale. Setting it exports **both** `HOST_LC_ALL` and `LANG`: since
Proton 10, Proton starts Wine with `LC_ALL=C`, which silently overrides a
lone `LANG` (ValveSoftware/Proton#9156) — so `LANG` alone no longer works.

No sudo or host changes needed in the common case: the container runtime
detects the requested locale and generates it inside the container
(`pv-locale-gen` lines in the log). If text still renders wrong, generate
the locale on the host (`/etc/locale.gen` + `sudo locale-gen`) and retry.

## Interface notes

* **A/B comparison** is structural: the unfiltered run launches with the
  layer environment entirely withheld, so the loader never sees vkBasalt.
  (Relying on the loader's disable flag is unreliable for explicitly-listed
  layers.) Proof: unfiltered logs contain zero vkBasalt lines.
* **Game icons** (GUI): extracted from Windows `.exe` files (`icoextract`),
  RPGMaker manifest art or shipped icon files, cached under
  `~/.cache/anime4k/icons/`. Missing sources fall back to a generic icon.
  Cached icons survive unplugged drives; delete the cache dir to refresh.
* **File pickers** pin home, filesystem root and every mounted drive under
  `/run/media/$USER`, and remember the last-used folder. Paths can always
  be pasted instead.
* **Logs** belong to the selected game: switching games clears the log view.
