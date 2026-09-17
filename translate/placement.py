#!/usr/bin/env python3
"""placement.py — compositor-agnostic window placement for the textbox.

Wayland clients cannot set their own position, tiling compositors ignore the
float hint, and a window that maps tiled loses its geometry before the app can
float it. This module requests the right behaviour BEFORE the window maps:

* Hyprland / sway: install a float rule (and size/position) so the first map is
  already floating at the saved spot.
* Any other compositor (KDE, GNOME, X11, …): windows already float, so Qt's
  saveGeometry/restoreGeometry handles size (and position on X11). No-op here.

All methods are best-effort and never raise: a failure silently falls back to
the pre-existing behaviour. See docs/translate.md.
"""
import json
import os
import shutil
import subprocess

TITLE = "vn-translate"


def _run(argv, timeout=5):
    try:
        return subprocess.run(argv, capture_output=True, text=True,
                              timeout=timeout)
    except (OSError, subprocess.SubprocessError):
        return None


class Placement:
    """Generic fallback: compositors that float normal windows need nothing."""
    name = "generic"

    def pre_map(self, saved):
        pass

    def after_map(self, saved):
        pass

    def capture(self, pid):
        return None


class HyprlandPlacement(Placement):
    name = "hyprland"

    def _json(self, *args):
        r = _run(["hyprctl", *args, "-j"])
        try:
            return json.loads(r.stdout) if r else None
        except (ValueError, AttributeError):
            return None

    def _eval(self, lua):
        _run(["hyprctl", "eval", lua])

    def _to_local(self, x, y):
        monitors = self._json("monitors")
        if not isinstance(monitors, list):
            return None
        for m in monitors:
            try:
                mx, my = int(m["x"]), int(m["y"])
                mw, mh = int(m["width"]), int(m["height"])
            except (KeyError, TypeError, ValueError):
                continue
            if mx <= x < mx + mw and my <= y < my + mh:
                return x - mx, y - my
        return None

    def pre_map(self, saved):
        move = ""
        if saved and saved.get("x") is not None and saved.get("y") is not None:
            try:
                local = self._to_local(int(saved["x"]), int(saved["y"]))
            except (TypeError, ValueError):
                local = None
            if local:
                move = f', move="{local[0]} {local[1]}"'
        # Re-declaring the same name updates the rule; disabling the previous
        # handle guards against duplicates if that is not the case.
        lua = ("pcall(function() if _G.__a4k_tb_rule then "
               "_G.__a4k_tb_rule:set_enabled(false) end end) "
               "_G.__a4k_tb_rule = hl.window_rule({ "
               f'name="anime4k-vn-textbox", match={{ title="^{TITLE}$" }}, '
               f"float=true, persistent_size=true{move} }})")
        self._eval(lua)

    def capture(self, pid):
        clients = self._json("clients")
        if not isinstance(clients, list):
            return None
        for c in clients:
            try:
                if int(c.get("pid", -1)) != pid:
                    continue
                at, size = c.get("at"), c.get("size")
                return {"x": int(at[0]), "y": int(at[1]),
                        "w": int(size[0]), "h": int(size[1])}
            except (TypeError, ValueError, IndexError):
                continue
        return None


class SwayPlacement(Placement):
    name = "sway"

    def _msg(self, *args, cmd=None):
        argv = ["swaymsg"] + list(args)
        if cmd is not None:
            argv.append(cmd)
        return _run(argv)

    def pre_map(self, saved):
        self._msg(cmd=f'for_window [title="^{TITLE}$"] floating enable')

    def after_map(self, saved):
        if not saved:
            return
        parts = []
        if saved.get("w") and saved.get("h"):
            parts.append(f"resize set {int(saved['w'])} {int(saved['h'])}")
        if saved.get("x") is not None and saved.get("y") is not None:
            parts.append(f"move position {int(saved['x'])} {int(saved['y'])}")
        for p in parts:
            self._msg(cmd=f'[title="^{TITLE}$"] {p}')

    def _tree(self):
        r = self._msg("-t", "get_tree")
        try:
            return json.loads(r.stdout) if r else None
        except (ValueError, AttributeError):
            return None

    def capture(self, pid):
        tree = self._tree()
        if not isinstance(tree, dict):
            return None
        stack = [tree]
        while stack:
            n = stack.pop()
            if n.get("pid") == pid and n.get("rect"):
                r = n["rect"]
                return {"x": int(r["x"]), "y": int(r["y"]),
                        "w": int(r["width"]), "h": int(r["height"])}
            stack.extend(n.get("nodes", []))
            stack.extend(n.get("floating_nodes", []))
        return None


def detect():
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and shutil.which("hyprctl"):
        return HyprlandPlacement()
    if os.environ.get("SWAYSOCK") and shutil.which("swaymsg"):
        return SwayPlacement()
    return Placement()
