# VN translation

Hooked Japanese dialogue from Proton VNs, translated live via DeepL into a
Luna-style textbox — composed with the Restore filter in a single launch.
`translate/` holds the implementation; this page is the operator manual.

## Flow

1. **Enable** per game: GUI game wizard/edit (Translation page) or
   `anime4k edit` → `translate`. Proton/Windows games only.
2. **First run (Setup Text Hooker for translation)**: this GUI button (or
   `anime4k` launch, which auto-uses setup while no hook is recorded)
   launches the game and opens the Text Hooker picker. Textractor opens
   **already attached** with the saved-thread list loaded, and the textbox
   opens alongside following Textractor's selection — so you see live
   translation while picking. The picker waits for the bridge to come up
   (the game must be running), then samples 20s of live threads. Advance the
   game text, then either:
   - click the story thread in the picker (name + last line) — no Textractor
     interaction at all — or
   - click the story thread in Textractor and press **Save hook(s)** — the
     hook code is harvested into the game entry automatically at session
     end (nothing is copied by hand).
   Either way the chosen thread/hook is stored in the game entry.
3. **Daily play**: `Translate` (Textractor hidden — the only difference from
   Setup; the recorded hook auto-inserts all the same). The textbox opens
   with it, following the recorded thread. It toggles EN-only / JA+EN. The
   standalone Textbox button just re-opens the reader onto a live session.
4. **End**: Stop in the UI (or Ctrl-C); `--stop` also drops the wineserver
   so the next launch boots fresh. Stop ends the whole session: game hooks,
   textbox backend, and its isolated DeepL browser (a backend left running
   would keep translating and re-show on new text).

## Architecture (one picture)

One `umu-run` → `wscript` → per-game `C:\hook\<id>.vbs` starts Textractor
(`/pgame.exe` = attach on boot) + game in a single Wine session (one
wineserver — dual containers serialize and never boot, proven twice).
Auto-attach comes from `SavedHooks.txt`/`SavedGames.txt`, seeded by the
launcher from the game entry (recorded hook auto-inserts; user-saved lines
always win). The v2 bridge streams **every** thread tagged with its
identity (`~#<num>[*]~<addr>~<name>~<text>`, `*` = Textractor's own
selection) on `:6677`; native code filters by thread, translates (Brave CDP
DeepL primary, local DLX fallback) and displays.

Filter + translation compose: `vn-launch.sh --filter <variant>` applies the
same vkBasalt mechanism as `proton-anime4k.sh`. A/B unfiltered launches stay
untranslated by design.

## Thread picking without Textractor

The v2 bridge tags every sentence with thread number, hook address, and
hook name (stable across sessions). The Text Hooker picker (opened by Setup
Text Hooker for translation, waiting for the bridge first) samples 20s of
live traffic and lists candidates with their last line; choosing one stores it
as the game's `translate.thread` and the Textbox/hook_client then follow
that thread by name (falling back to Textractor's selection if unset —
stock-bridge installs simply keep following the selection). Manual control:
`hook_client.py --thread <name|number|hex-addr|*>`, `textbox.py --thread …`,
`vn-translate --thread …`.

## Hook ladder (unknown engine? work down, stop at first clean thread)

1. **Engine hook** (`vnreng: INSERT <name>` at attach): pick it (picker or
   Textractor), remove the generic bulk (see rule below), Save hooks.
2. **Minimal generic set**: no engine hook → keep only `TextOut`/`ExtTextOut`
   (+ `W`/`A` as needed); add hooks only while silent.
3. **Junk filters**: Textractor's Remove Repeated Characters/Phrases + Regex
   Filter for GDI noise.
4. **Hook search last**: crash-prone — in-game save first.

## Crash doctrine (proven across sessions, do not rediscover)

* **Keep the extension set stripped: bridge only.** Proven live: with the
  full stock set (Google Translate ext ON, target Tajik) the hook fired in
  Textractor yet the bridge stayed totally silent for minutes; unchecking
  everything but `textractor_websocket` restored tagged traffic instantly.
  A loaded translate ext can stall the whole sentence pipeline, so translate
  in the textbox, never in Textractor.
* **Remove, don't deselect.** Unselected hooks stay inserted and keep
  processing. Four crashes with the GDI bulk inserted, zero Anim3-only —
  but bulk is *not* universally fatal (one title stable with everything),
  so removal is remedy, not ritual. Record per-game behavior.
* **cwd decides engine detection.** Launchers must set each program's working
  directory (VBS `CurrentDirectory`); without it, engine hooks don't insert.
* **Never bare-TCP `:6677`.** The stock bridge panics the host on
  non-handshake connections (and on abrupt disconnects); every health check
  must complete a real websocket handshake. The hardened fork (default)
  degrades gracefully instead.
* **Registered `.xdll`, not `.dll`.** Textractor loads the renamed copy —
  install any bridge build under BOTH filenames or sessions silently run
  the other one.
* **SavedHooks/SavedGames lines must be bare-LF/CR-stripped**: upstream
  exact-matches them against process paths; a stray `\r` (Wine CRLF
  defaults) silently disables auto-attach. The launcher normalizes both.
* **Stale wineserver wedges new containers** (launcher exits silently, nothing
  spawns). The shipped launcher blocks on the *game*, `--stop` also drops the
  server, the GUI refuses double-launches and offers Stop && Launch /
  Clear && Launch on live/wedged state. Always stop before relaunching.
* **One ws client besides Textractor itself.** Extra ad-hoc taps raise crash
  odds on stock; the fixed bridge tolerates them.
* Textractor's `SavedHooks.txt` writes survive clean exits; the library
  (`translate.hook_code`, auto-harvested) is the portable source of truth.

## Bridge builds

* **Stock** kuroahna 0.2.0 (upstream, MIT/Apache): works, fragile (see
  above); only the Textractor-selected thread flows, untagged.
* **Fixed fork v2** (default): host-safety patches (no panics,
  non-blocking lossy host send, 256-deep drain-all queue, double-init
  tolerated) **plus** the thread-tagged broadcast that powers the native
  picker. A/B proven. Rebuild from `translate/bridge-fork.patch`
  (rustup stable + `i686-pc-windows-gnu` + mingw-w64-gcc; the fork's
  `textractor.rs` decodes `"text name"` as UTF-16 — upstream passes a
  `wchar_t*`); the prebuilt DLL is used from the `translate-v2` release asset
  when published, else the stock build — sha256-verified at install.

## DeepL browser (hidden by default)

Translation drives deepl.com through an isolated Chromium/Brave profile over
CDP. The browser runs **headless** (`--headless=new`), so no window appears and
nothing steals focus. Per game, the Translation page has **Show the DeepL
browser window (debug)** — tick it to watch the automation (remembered per
game; both Translate and Setup Text Hooker honour it). Globally, set
`"browser_hidden": false` in `translate/config.json`. The browser is
single-instance and reused while its debug port is live, so stop the session
before a visibility change takes effect.

It keeps exactly **one** DeepL tab: the launcher reuses an existing tab,
closes any extras, and purges stale session state before a fresh start, so a
new session never reopens a pile of DeepL pages. On Stop — and when the
textbox window closes — the browser closes its tabs and exits cleanly
(`Browser.close`) instead of being killed, so it never session-restores.
Both the purge and the close are guarded to the isolated automation profile:
a browser that wasn't started with that `--user-data-dir` is never touched,
and the real browser profile is never read or modified.

## Textbox on Hyprland (Float + Click + Top)

* **Click** = click-through. Clicks on the text area fall through to the game
  below; hovering either bar (titlebar or toolbar) restores full input so
  Top/Click stay clickable and the window stays draggable. (Technical note:
  click-through is a bars-only surface input mask; `Qt.WindowTransparentForInput`
  is deliberately never set — while it is set, Qt silently drops every mask
  update. Both facts verified at the Wayland protocol level.)
* **Float** is enforced unconditionally (an overlay must never tile): a
  Hyprland poller float-enables the window at map and re-floats it if
  something tiles it, independent of Top. No config change needed — works on
  any Hyprland ≥ 0.55 the app is run from.
* **Top** = pinned to the box's workspace, above everything there. Qt's
  stay-on-top hint is ignored by Hyprland, so a ~1s poller enforces it: pinned
  while Top is on *and* you're on the box's workspace, unpinned everywhere
  else (stays put, normal stacking, freely movable — including Top-off
  state). Leaving drags it along once (pin mechanics), then it unpins and
  simply stays where it landed — it is deliberately never moved back, because
  moving a window makes the compositor flip the active workspace to follow
  it, which fights you in a loop. Coming back repins it into view. Moving it by hand adopts the new workspace as home
  (follow-residue can never fake a move: adoption needs a workspace edge
  while unpinned; re-arm any time with a Top toggle). Every new translated
  line also raises it (no focus steal). An old session rule once pinned this
  title everywhere; the poller + map-time unpin neutralize it. Corner
  rounding follows the compositor (`decoration:rounding`, Style override
  available).
* Optional Hyprland rule to float it at map time (avoids the brief tiled
  moment before the app's poller floats it; lua syntax, Hyprland ≥ 0.55):
  ```lua
  hl.window_rule({
    name = "vn-translate-overlay",
    match = { title = "^vn-translate$" },
    float = true,
  })
  ```
  (The app manages float + pin itself; add `pin = true` only if you want the
  box on *every* workspace regardless of Top.)
  Verified on Hyprland 0.56.2 + Qt 6.11.

## Textbox style

`translate/textbox.py` is a Qt Quick readout: same pipeline and window
behavior as always, but text styling binds live — font size/family/color
changes restyle the whole history, including existing lines. Window chrome
(bars, panel, drawer and the default text colours) follows the desktop
colour scheme through the KDE Quick Controls style, same as the launcher
GUI. The **Style**
toolbar button opens a drawer with font, size, EN/JA colors, a soft text
**shadow** (GPU halo that keeps text selectable), background **opacity**,
top/bottom-bar **autohide** (bars reveal when the cursor enters their edge
strips), and corner rounding (follows the compositor's
`decoration:rounding`, override in the drawer). All prefs persist in the
textbox settings store. The launcher refuses a second backend (two would
fight over one DeepL page); closing the window quits it, so it can never
resurrect on new text. There is no scrollbar — the view sticks to the
bottom and scrolls when you scroll up.

## Per-game notes

* **mlove** (Anim engine): hook `HSX10@54DC0:mlove.exe`, story thread
  `Anim3` (addr `454DC0`). Anim3-only required (GDI bulk crashed 4×).
  Reference title.
* **mmg / Start.exe** (Atelier KAGUYA2/6 engine hooks): generic-ladder
  title, bulk-tolerant so far.

## Install behavior

`install.sh` offers translation support (default Yes): fetches the pinned
Textractor bundle + bridge (fixed v2 asset preferred, stock fallback),
installs into the shared prefix, symlinks `vn-launch` / `vn-textbox` /
`vn-translate`.
Settings come from `translate/config.json` and the games registry from
`translate/translate.json` — both seeded from their `.sample` files on
first install (never overwritten); the Python entry points also start on a
bare clone by falling back to the samples/builtins. DLX server is opt-in
(offline fallback on `:1188`). `requirements.md` lists every dependency per
distro. `install.sh --check-only` audits the translate deps too.

## Limits

* Proton/Windows games only (hook injection needs Wine + one shared session).
* One live session at a time (shared prefix design).
* The Text Hooker needs live text: run Setup Text Hooker for translation and
  advance the game while it samples. Thread picking by name needs the v2
  bridge — stock installs follow Textractor's selection instead.
* Sentence-MT quirks: speaker names romanize inconsistently across lines.
