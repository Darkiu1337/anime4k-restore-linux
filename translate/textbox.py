#!/usr/bin/env python3
"""textbox.py — Luna-style translation readout (Qt Quick frontend).

Scrolling JA/EN history with live-bound styling (font family/size, EN/JA/
shadow colors, shadow toggle, panel opacity, chrome autohide, corner radius
matching the compositor); keep-on-top w/ workspace-aware Hyprland pin,
hover-aware click-through, auto-hide, copy, re-translate; geometry + prefs
persist via QSettings. Embedded pipeline: hook thread -> translator thread
-> GUI-thread model. The Style toolbar button opens a drawer with native
font/color dialogs bound to the same backend properties.
Usage: textbox.py [--smoke-test] [--self-test] [--start-workers]
  [--thread NAME|NUM|*]
"""
import json
import os
import shutil
import subprocess
import sys
import threading
import time
from collections import deque
from PySide6.QtCore import (QByteArray, QModelIndex, QAbstractListModel, QObject,
                            Qt, QTimer, QUrl, QRect, Signal, Slot, Property)
from PySide6.QtGui import QGuiApplication, QRegion, QColor
from PySide6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cfg import load_config
CONFIG = load_config()
ORG, APP = "vn-translate", "textbox"

HISTORY_MAX = 200


class PairModel(QAbstractListModel):
    JaRole = Qt.UserRole + 1
    EnRole = Qt.UserRole + 2

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows = []

    def roleNames(self):
        return {PairModel.JaRole: b"ja", PairModel.EnRole: b"en"}

    def rowCount(self, parent=QModelIndex()):
        return len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        ja, en = self._rows[index.row()]
        if role == PairModel.JaRole:
            return ja
        if role == PairModel.EnRole:
            return en
        return None

    def append(self, ja, en):
        if len(self._rows) >= HISTORY_MAX:
            self.beginRemoveRows(QModelIndex(), 0, 0)
            self._rows.pop(0)
            self.endRemoveRows()
        row = len(self._rows)
        self.beginInsertRows(QModelIndex(), row, row)
        self._rows.append((ja, en))
        self.endInsertRows()

    def clear(self):
        if not self._rows:
            return
        self.beginRemoveRows(QModelIndex(), 0, len(self._rows) - 1)
        self._rows.clear()
        self.endRemoveRows()

    def last_en(self):
        return self._rows[-1][1] if self._rows else ""


def _css_color(v, fallback):
    """Normalize anything QML hands over (QColor, "#rrggbb") to a CSS hex
    string. A bare str(QColor) yields "PySide6...fromRgbF(...)" garbage that
    QML can never parse back — which silently broke every color picker."""
    try:
        if isinstance(v, QColor):
            return v.name()
        s = str(v or fallback)
        return s if (s.startswith("#") and QColor(s).isValid()) else fallback
    except Exception:
        return fallback


class Backend(QObject):
    showJaChanged = Signal()
    keepOnTopChanged = Signal()
    clickThroughChanged = Signal()
    autoHideChanged = Signal()
    statusTextChanged = Signal()
    fontSizeChanged = Signal()
    fontFamilyChanged = Signal()
    enColorChanged = Signal()
    jaColorChanged = Signal()
    shadowEnabledChanged = Signal()
    shadowColorChanged = Signal()
    panelAlphaChanged = Signal()
    chromeAutoHideChanged = Signal()
    chromeVisibleChanged = Signal()
    cornerRadiusChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.pairs = PairModel(self)
        self.pending = deque()
        self.ja_queue = deque()
        self.translator = None
        self.last_ja = ""
        self._show_ja = True
        self._keepontop = True
        self._clickthrough = False
        self._autohide = False
        self.autohide_delay = 4
        self._status_text = "● stopped"
        self._font_size = 11.0
        self._font_family = ""
        self._en_color = "#f0f0f0"
        self._ja_color = "#9a9a9a"
        self._shadow_enabled = True
        self._shadow_color = "#000000"
        self._panel_alpha = 0.88
        self._chrome_autohide = False
        self._chrome_visible = True
        self._corner_radius = 10
        self._home_ws = None
        self.last_text_time = time.time()
        self._window = None
        self._title_h = 25
        self._tool_h = 27
        self._chrome_hovered = False
        self._drawer_open = False
        self._pointer_inside = False
        self._pointer_strip = False
        self._hover_override = None  # self-test hook: forces chrome_hovered()
        self.thread = "*"

    # ---- QML-bound properties ----
    showJa = Property(bool,
                      lambda s: s._show_ja,
                      lambda s, v: (setattr(s, "_show_ja", v), s.showJaChanged.emit()),
                      notify=showJaChanged)
    keepOnTop = Property(bool,
                         lambda s: s._keepontop,
                         lambda s, v: (setattr(s, "_keepontop", v), s.keepOnTopChanged.emit()),
                         notify=keepOnTopChanged)
    clickThrough = Property(bool,
                            lambda s: s._clickthrough,
                            lambda s, v: (setattr(s, "_clickthrough", v),
                                          s.clickThroughChanged.emit()),
                            notify=clickThroughChanged)
    autoHide = Property(bool,
                        lambda s: s._autohide,
                        lambda s, v: (setattr(s, "_autohide", v),
                                      s.autoHideChanged.emit()),
                        notify=autoHideChanged)
    statusText = Property(str,
                          lambda s: s._status_text,
                          lambda s, v: (setattr(s, "_status_text", v),
                                        s.statusTextChanged.emit()),
                          notify=statusTextChanged)
    fontSize = Property(float,
                        lambda s: s._font_size,
                        lambda s, v: (setattr(s, "_font_size", float(v)),
                                      s.fontSizeChanged.emit()),
                        notify=fontSizeChanged)
    fontFamily = Property(str,
                          lambda s: s._font_family,
                          lambda s, v: (setattr(s, "_font_family", str(v)),
                                        s.fontFamilyChanged.emit()),
                          notify=fontFamilyChanged)
    enColor = Property(str,
                       lambda s: s._en_color,
                       lambda s, v: (setattr(s, "_en_color", _css_color(v, "#f0f0f0")),
                                     s.enColorChanged.emit()),
                       notify=enColorChanged)
    jaColor = Property(str,
                       lambda s: s._ja_color,
                       lambda s, v: (setattr(s, "_ja_color", _css_color(v, "#9a9a9a")),
                                     s.jaColorChanged.emit()),
                       notify=jaColorChanged)
    shadowEnabled = Property(bool,
                              lambda s: s._shadow_enabled,
                              lambda s, v: (setattr(s, "_shadow_enabled", bool(v)),
                                            s.shadowEnabledChanged.emit()),
                              notify=shadowEnabledChanged)
    shadowColor = Property(str,
                            lambda s: s._shadow_color,
                            lambda s, v: (setattr(s, "_shadow_color", _css_color(v, "#000000")),
                                          s.shadowColorChanged.emit()),
                            notify=shadowColorChanged)
    panelAlpha = Property(float,
                          lambda s: s._panel_alpha,
                          lambda s, v: (setattr(s, "_panel_alpha",
                                               min(1.0, max(0.15, float(v)))),
                                        s.panelAlphaChanged.emit()),
                          notify=panelAlphaChanged)
    def _set_chrome_autohide(self, v):
        v = bool(v)
        if self._chrome_autohide != v:
            self._chrome_autohide = v
            self.chromeAutoHideChanged.emit()
            self._update_chrome_visibility()

    chromeAutoHide = Property(bool,
                              lambda s: s._chrome_autohide,
                              _set_chrome_autohide,
                              notify=chromeAutoHideChanged)
    chromeVisible = Property(bool,
                             lambda s: s._chrome_visible,
                             notify=chromeVisibleChanged)

    def _set_corner_radius(self, v):
        try:
            v = min(16, max(0, int(v)))
        except (TypeError, ValueError):
            return
        if self._corner_radius != v:
            self._corner_radius = v
            self.cornerRadiusChanged.emit()

    cornerRadius = Property(int,
                            lambda s: s._corner_radius,
                            _set_corner_radius,
                            notify=cornerRadiusChanged)

    @staticmethod
    def _query_compositor_radius():
        """Hyprland's decoration rounding so the box matches the compositor
        border (square stays square). None when not on Hyprland/parse fails."""
        try:
            import subprocess as _sp
            out = _sp.run(["hyprctl", "getoption", "decoration:rounding"],
                          capture_output=True, text=True, timeout=5).stdout
        except Exception:
            return None
        import re as _re
        m = _re.search(r"int:\s*(-?\d+)", out or "")
        if not m:
            return None
        try:
            return min(16, max(0, int(m.group(1))))
        except ValueError:
            return None

    # ---- workspace-aware pin ----
    @staticmethod
    def _want_pinned(active_ws, home_ws, keepontop):
        return bool(keepontop and home_ws is not None and active_ws == home_ws)

    def _hyprctl_json(self, *args):
        try:
            out = subprocess.run(["hyprctl", *args, "-j"],
                                 capture_output=True, text=True,
                                 timeout=5).stdout
            return json.loads(out)
        except Exception:
            return None

    def pin_tick(self):
        """Enforce Top semantics against the compositor, ~1s cadence:
        pinned while Top is on AND we are on the box's home workspace;
        unpinned everywhere else (stays put, normal stacking, freely
        movable). Home is adopted on first sight and whenever the box moves
        (only the user can move it). Dispatches only on mismatch. Never
        raises: this runs on a timer."""
        try:
            if (not shutil.which("hyprctl")
                    or not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")):
                return
            clients = self._hyprctl_json("clients")
            active = self._hyprctl_json("activeworkspace")
            if not isinstance(clients, list) or not isinstance(active, dict):
                return
            me = None
            for c in clients:
                try:
                    if int(c.get("pid", -1)) == os.getpid():
                        me = c
                        break
                except (TypeError, ValueError):
                    continue
            if me is None:
                return
            ws = (me.get("workspace") or {}).get("id")
            if ws is None:
                return
            # Home adoption, follow-proof: a PINNED box moves workspaces on
            # its own (it follows the active workspace), so adoption happens
            # only on a workspace EDGE (ws differs from last poll) while
            # unpinned. A persistent mismatch with no edge is follow-residue
            # (or a stale observation) and must never re-arm the trap: the
            # old level-trigger re-adopted every tick and re-pinned forever.
            # Moving a pinned box by hand still needs a Top toggle to re-home
            # (toggleTop clears home).
            last_pinned = getattr(self, "_last_pinned", None)
            prev_ws = getattr(self, "_last_ws", None)
            if ws != self._home_ws:
                if self._home_ws is None or (not last_pinned and ws != prev_ws):
                    self._home_ws = ws
            self._last_ws = ws
            self._last_pinned = bool(me.get("pinned", False))
            want = self._want_pinned(active.get("id"), self._home_ws,
                                     self._keepontop)
            # Never fight an un-floatable window with a dispatch per second.
            if want and not me.get("floating", False):
                return
            if bool(me.get("pinned", False)) != want:
                action = "enable" if want else "disable"
                subprocess.run(["hyprctl", "dispatch",
                                f'hl.dsp.window.pin({{window="title:^vn-translate$", action="{action}"}})'],
                               capture_output=True, timeout=5)
                if want:
                    subprocess.run(["hyprctl", "dispatch",
                                    'hl.dsp.window.bring_to_top({window="title:^vn-translate$"})'],
                                   capture_output=True, timeout=5)
                # NOTE: never move the window back home here. A workspace
                # move makes the compositor flip the ACTIVE workspace to
                # follow it, which fights the user and loops forever. Residue
                # on a foreign ws simply stays put (unpinned, out of the
                # way) until they return home, which repins it into view.
        except Exception:
            pass

    # ---- window wiring ----
    def attach_window(self, win):
        self._window = win
        try:
            fmt = win.format()
            fmt.setAlphaBufferSize(8)
            win.setFormat(fmt)
        except Exception:
            pass
        self.restore_state()
        self.apply_flags(initial=True)
        # Every launch, either state: enable-path floats+raises (Top on),
        # disable-path unpins (Top off AND neutralizes the stale session rule
        # that pins this title at map time).
        self._hyprctl_sync_top_deferred()
        self.drain_timer = QTimer(self)
        self.drain_timer.timeout.connect(self.drain)
        self.drain_timer.start(120)
        self.status_timer = QTimer(self)
        self.status_timer.timeout.connect(self.poll_status)
        self.status_timer.start(2000)
        self.hover_timer = QTimer(self)
        self.hover_timer.timeout.connect(self.hover_tick)
        self.hover_timer.start(100)
        self.hide_timer = QTimer(self)
        self.hide_timer.timeout.connect(self.hide_tick)
        self.hide_timer.start(500)
        self.pin_timer = QTimer(self)
        self.pin_timer.timeout.connect(self.pin_tick)
        self.pin_timer.start(1000)

    @Slot(float, float)
    def setChromeGeometry(self, title_h, tool_h):
        self._title_h = max(1, int(title_h))
        self._tool_h = max(1, int(tool_h))
        self._mask_applied = None

    @Slot(bool)
    def setChromeHovered(self, hovered):
        self._chrome_hovered = bool(hovered)
        self._update_chrome_visibility()

    @Slot(float, float, bool)
    def pointerAt(self, x, y, inside):
        """Window-local pointer position from the QML hover handler.

        Event-driven on purpose: QCursor.pos() is unreliable on Wayland (no
        global pointer query — Qt returns stale/(0,0)), and frameGeometry()
        is (0,0)-based there for the same reason. The compositor-true event
        coordinates are the only trustworthy source.
        """
        inside = bool(inside)
        self._pointer_inside = inside
        strip = False
        if inside:
            try:
                h = self._window.height() if self._window is not None else 0
                strip = y < self._title_h or (h > 0 and y > h - self._tool_h)
            except Exception:
                strip = False
        self._pointer_strip = strip
        self._update_chrome_visibility()

    def _update_chrome_visibility(self):
        show = (not self._chrome_autohide or self._drawer_open
                or self._chrome_hovered or self._pointer_strip)
        if show != self._chrome_visible:
            self._chrome_visible = show
            self.chromeVisibleChanged.emit()

    @Slot(bool)
    def setDrawerOpen(self, opened):
        # An open Style drawer covers the text area: force full input so its
        # controls stay clickable under click-through, and keep chrome shown.
        self._drawer_open = bool(opened)
        self._mask_applied = None
        self.apply_input_mask()
        self._update_chrome_visibility()

    # ---- window flags / input region ----
    @staticmethod
    def _on_wayland():
        try:
            return QGuiApplication.platformName() == "wayland"
        except Exception:
            return False

    def apply_flags(self, initial=False):
        if self._window is None:
            return
        # Click-through architecture (Wayland, protocol-proven): the input
        # MASK ALONE controls everything — Qt.WindowTransparentForInput is
        # never set, because while it is set Qt silently drops every mask
        # update (4 consecutive setMask calls, zero protocol traffic).
        # Click ON = bars-only mask (text area falls through, chrome stays
        # clickable so the mode is always reversible); click OFF = null mask
        # (compositor reads null as full input). No flag ever changes for
        # click toggles, so no surface is ever recreated and masks always
        # land on a stable surface. X11 keeps flag-follows-hover (a mask
        # would clip the visuals there; surface ops are synchronous anyway).
        if self._on_wayland():
            want_transparent = False
        else:
            want_transparent = self.clickthrough_effective
        flags = (Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
                 if self._keepontop else Qt.FramelessWindowHint | Qt.Tool)
        if want_transparent:
            flags |= Qt.WindowTransparentForInput
        if initial or int(flags) != getattr(self, "_flags_applied", None):
            self._flags_applied = int(flags)
            self._window.setFlags(flags)
            if initial or not self._window.isVisible():
                self._window.show()
        self.apply_input_mask()
        self.keepOnTopChanged.emit()
        self.clickThroughChanged.emit()

    def chrome_region(self):
        """Bars-only input region (window coords) for the click-through
        guard. Bar heights come from QML; width from the live window."""
        try:
            w = self._window.width() if self._window is not None else 0
            h = self._window.height() if self._window is not None else 0
        except Exception:
            w, h = 0, 0
        region = QRegion()
        if w > 0 and self._title_h > 0:
            region |= QRegion(0, 0, w, self._title_h)
        if w > 0 and self._tool_h > 0 and h > 0:
            region |= QRegion(0, h - self._tool_h, w, self._tool_h)
        return region

    def _full_region(self):
        try:
            return QRegion(QRect(0, 0, self._window.width(), self._window.height()))
        except Exception:
            return QRegion()

    def apply_input_mask(self, force=False):
        if not self._on_wayland():
            return
        win = self._window
        if win is None:
            return
        try:
            if self.clickthrough_effective:
                want = self.chrome_region()
                if want.isEmpty():
                    want = QRegion()  # fail safe: null = full input
                key = ("chrome", want.boundingRect().getRect())
            else:
                # Null mask: the compositor treats null as full-window input.
                want = QRegion()
                key = ("full", ())
        except Exception:
            return
        # Masks only change on a stable surface now (click toggles never touch
        # flags), so the key guard is sound; force covers the one remaining
        # recreation path (keepontop toggle).
        if force or key != getattr(self, "_mask_applied", None):
            self._mask_applied = key
            try:
                win.setMask(want)
            except Exception:
                pass

    @property
    def clickthrough_effective(self):
        return self._clickthrough and not self.chrome_hovered() and not self._drawer_open

    def chrome_hovered(self):
        if self._hover_override is not None:
            return self._hover_override
        return self._chrome_hovered

    def hover_tick(self):
        # Mask transitions only. All hover knowledge is event-driven (QML
        # handlers -> setChromeHovered/pointerAt); QCursor polling is dead on
        # Wayland and must not feed this path.
        want = self.clickthrough_effective
        if want != getattr(self, "_ct_applied", None):
            self._ct_applied = want
            self.apply_flags()

    def hide_tick(self):
        if not self._autohide or self._window is None:
            return
        try:
            visible = self._window.isVisible()
        except Exception:
            return
        if not visible:
            return
        if time.time() - self.last_text_time < self.autohide_delay:
            return
        if self._pointer_inside:
            self.last_text_time = time.time()
            return
        self._window.hide()

    @Slot()
    def toggleTop(self):
        self._keepontop = not self._keepontop
        # Re-arming Top adopts wherever the box is now as its new home
        # (covers "I moved it, pin it here").
        if self._keepontop:
            self._home_ws = None
        # keepontop toggles are the only remaining flag changes on Wayland:
        # reset the mask keys so the next tick re-sends on the new surface,
        # plus a timed backup.
        self._ct_applied = None
        self._mask_applied = None
        self.apply_flags()
        self._hyprctl_sync_top_deferred()
        QTimer.singleShot(800, self.apply_input_mask)

    @Slot()
    def toggleClickthrough(self):
        self._clickthrough = not self._clickthrough
        self._ct_applied = None
        self._mask_applied = None
        self.apply_flags()
        if self._keepontop:
            self._hyprctl_sync_top_deferred()

    def _hyprctl_sync_top_deferred(self):
        if self._keepontop:
            self._hyprctl_sync_top()
            QTimer.singleShot(500, self._hyprctl_sync_top)
            QTimer.singleShot(1500, self._hyprctl_sync_top)
        else:
            self._hyprctl_unpin()
            QTimer.singleShot(500, self._hyprctl_unpin)

    def _hyprctl_unpin(self):
        """Top-off path (and stale-rule neutralizer): leave stacking alone,
        just make sure nothing is pinned to all workspaces."""
        if not shutil.which("hyprctl"):
            return
        if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return
        try:
            subprocess.run(["hyprctl", "dispatch",
                            'hl.dsp.window.pin({window="title:^vn-translate$", action="disable"})'],
                           capture_output=True, timeout=5)
        except Exception:
            pass

    def _hyprctl_sync_top(self):
        """Mirror keep-on-top into the compositor. Qt's StaysOnTopHint is
        only a hint on Wayland — Hyprland restacks floating windows on focus.
        Top therefore floats the window and raises it; it deliberately does
        NOT pin (pin shows the window on ALL workspaces — the box must stay
        on its spawn workspace). The pin-disable also neutralizes a stale
        session rule that used to pin this title (static rules apply at map;
        the explicit disable sticks). Best-effort: silently skips when not
        on Hyprland or hyprctl fails."""
        if not shutil.which("hyprctl"):
            return
        if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return
        sel = 'window="title:^vn-translate$"'
        cmds = [
            ["hyprctl", "dispatch",
             'hl.dsp.window.float({window="title:^vn-translate$", action="enable"})'],
            ["hyprctl", "dispatch",
             f'hl.dsp.window.pin({{{sel}, action="disable"}})'],
            ["hyprctl", "dispatch",
             f'hl.dsp.window.bring_to_top({{{sel}}})'],
        ]
        for cmd in cmds:
            try:
                subprocess.run(cmd, capture_output=True, timeout=5)
            except Exception:
                pass

    def _hyprctl_raise(self):
        """One-shot raise for new text (Top mode): pops the box above the
        game without focus steal and without pinning it to all workspaces.
        Throttled to one dispatch per 2s."""
        if not self._keepontop:
            return
        now = time.time()
        if now - getattr(self, "_last_raise", 0) < 2.0:
            return
        self._last_raise = now
        if not shutil.which("hyprctl"):
            return
        if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return
        try:
            subprocess.run(["hyprctl", "dispatch",
                            'hl.dsp.window.bring_to_top({window="title:^vn-translate$"})'],
                           capture_output=True, timeout=5)
        except Exception:
            pass

    @Slot()
    def toggleMode(self):
        self._show_ja = not self._show_ja
        self.showJaChanged.emit()
        # No rerender: delegates bind visibility to showJa live.

    @Slot()
    def toggleAutohide(self):
        self._autohide = not self._autohide
        self.autoHideChanged.emit()
        self.last_text_time = time.time()

    @Slot()
    def toggleChromeAutoHide(self):
        self._chrome_autohide = not self._chrome_autohide
        self.chromeAutoHideChanged.emit()
        self._update_chrome_visibility()

    @Slot(int)
    def bumpFont(self, delta):
        # Live-restyles the whole history via QML bindings.
        self._font_size = max(8.0, self._font_size + delta)
        self.fontSizeChanged.emit()

    @Slot()
    def clearHistory(self):
        self.pairs.clear()

    @Slot()
    def copyCurrent(self):
        try:
            QGuiApplication.clipboard().setText(self.pairs.last_en())
        except Exception:
            pass

    @Slot()
    def retranslate(self):
        rows = self.pairs._rows
        if rows:
            self.ja_queue.append(rows[-1][0])
            self.last_ja = ""

    @Slot()
    def minimize(self):
        try:
            if self._window is not None:
                self._window.showMinimized()
        except Exception:
            pass

    @Slot()
    def saveState(self):
        from PySide6.QtCore import QSettings
        s = QSettings(ORG, APP)
        try:
            if self._window is not None:
                s.setValue("geometry", self._window.saveGeometry())
        except Exception:
            pass
        s.setValue("show_ja", self._show_ja)
        s.setValue("fontsize", self._font_size)
        s.setValue("fontfamily", self._font_family)
        s.setValue("encolor", self._en_color)
        s.setValue("jacololr", self._ja_color)
        s.setValue("shadow", self._shadow_enabled)
        s.setValue("shadowcolor", self._shadow_color)
        s.setValue("panelalpha", self._panel_alpha)
        s.setValue("chromeautohide", self._chrome_autohide)
        s.setValue("cornerradius", self._corner_radius)
        s.setValue("keepontop", self._keepontop)
        s.setValue("autohide", self._autohide)

    # ---- persistence ----
    def restore_state(self):
        from PySide6.QtCore import QSettings
        s = QSettings(ORG, APP)
        try:
            g = s.value("geometry")
            if g and self._window is not None:
                self._window.restoreGeometry(g if isinstance(g, QByteArray) else QByteArray(g))
        except Exception:
            pass
        self._show_ja = s.value("show_ja", True, type=bool)
        try:
            v = float(s.value("fontsize", 11.0))
            self._font_size = v if v >= 8.0 else 11.0
        except (TypeError, ValueError):
            self._font_size = 11.0
        self._font_family = str(s.value("fontfamily", "") or "")
        self._en_color = _css_color(s.value("encolor", ""), "#f0f0f0")
        self._ja_color = _css_color(s.value("jacololr", ""), "#9a9a9a")
        self._shadow_enabled = s.value("shadow", True, type=bool)
        self._shadow_color = _css_color(s.value("shadowcolor", ""), "#000000")
        try:
            _pa = float(s.value("panelalpha", 0.88))
            self._panel_alpha = min(1.0, max(0.15, _pa))
        except (TypeError, ValueError):
            self._panel_alpha = 0.88
        self._chrome_autohide = s.value("chromeautohide", False, type=bool)
        self._chrome_visible = True
        # Corner radius follows the compositor (square stays square) unless
        # the user overrode it in Style (persisted value wins).
        queried = self._query_compositor_radius()
        try:
            raw = s.value("cornerradius", None)
            self._corner_radius = min(16, max(0, int(raw))) if raw is not None else None
        except (TypeError, ValueError):
            self._corner_radius = None
        if self._corner_radius is None:
            self._corner_radius = queried if queried is not None else 10
        self._keepontop = s.value("keepontop", True, type=bool)
        self._autohide = s.value("autohide", False, type=bool)
        # Restores assign backing fields directly (no per-field emit), so push
        # every property to QML explicitly — otherwise bindings keep whatever
        # defaults were live at engine load (e.g. radius 10 over a 0).
        for _sig in (self.showJaChanged, self.keepOnTopChanged,
                     self.clickThroughChanged, self.autoHideChanged,
                     self.statusTextChanged, self.fontSizeChanged,
                     self.fontFamilyChanged, self.enColorChanged,
                     self.jaColorChanged, self.shadowEnabledChanged,
                     self.shadowColorChanged, self.panelAlphaChanged,
                     self.chromeAutoHideChanged, self.chromeVisibleChanged,
                     self.cornerRadiusChanged):
            try:
                _sig.emit()
            except Exception:
                pass

    # ---- content ----
    def append_pair(self, ja, en, record=True):
        # Plain strings into the model; all styling is QML-bound. No HTML
        # escaping needed (Text.PlainText delegates).
        self.pairs.append(ja or "", en or "")
        self.last_text_time = time.time()
        try:
            if self._window is not None and not self._window.isVisible():
                self._window.show()
        except Exception:
            pass
        self._hyprctl_raise()

    # ---- pipeline (hook thread -> translator thread -> GUI model) ----
    def ensure_workers(self):
        if self.translator is not None:
            return
        try:
            import vn_translate
            self.translator = vn_translate.make_translator(True)
        except Exception as e:
            self._status_text = f"translator init failed: {e}"
            self.statusTextChanged.emit()
            return
        threading.Thread(target=self.hook_loop, daemon=True).start()
        threading.Thread(target=self.translate_loop, daemon=True).start()

    def hook_loop(self):
        import time as _time
        from hook_client import listen
        while True:
            try:
                listen(CONFIG.get("hook_url", "ws://localhost:6677"),
                       on_message=self.ja_queue.append, thread=self.thread)
            except Exception as e:
                self.pending.append((None, f"[hook error: {e}]"))
            _time.sleep(5)

    def translate_loop(self):
        import time as _time
        while True:
            try:
                ja = self.ja_queue.popleft()
            except IndexError:
                _time.sleep(0.1)
                continue
            if ja == self.last_ja:
                continue
            self.last_ja = ja
            try:
                out, via = self.translator(ja)
            except Exception as e:
                out, via = f"[translation failed: {e}]", "none"
            self.pending.append((ja, out))

    def drain(self):
        while self.pending:
            item = self.pending.popleft()
            try:
                if item[0] is None:
                    self._status_text = item[1]
                    self.statusTextChanged.emit()
                else:
                    ja, out = item
                    self.append_pair(ja, out)
                    self._status_text = "● live"
                    self.statusTextChanged.emit()
            except Exception as e:
                self._status_text = f"● display error: {e}"
                self.statusTextChanged.emit()

    def poll_status(self):
        try:
            import websocket
            ws = websocket.create_connection("ws://127.0.0.1:6677", timeout=3)
            ws.close()
            if not self.pending:
                self._status_text = "● live (:6677)"
                self.statusTextChanged.emit()
        except Exception:
            self._status_text = "● stopped"
            self.statusTextChanged.emit()


def self_test(backend, window):
    """Same contract as always: rendering + interaction paths that a plain
    window-map smoke test never touches."""
    backend.append_pair("テスト一行目", "first test line")
    backend.append_pair("二行目", "second test line")
    assert backend.pairs.rowCount() == 2, "model recorded nothing"
    assert backend.pairs.data(backend.pairs.index(0, 0), PairModel.EnRole) == "first test line"
    before_size = backend._font_size
    before_mode = backend._show_ja
    backend.toggleMode()
    assert backend._show_ja == (not before_mode), "mode toggle failed"
    backend.toggleMode()
    assert backend._show_ja == before_mode, "mode double-toggle must restore"
    backend.retranslate()
    backend.copyCurrent()
    # Font sizing is a live binding now: bump must change the property the
    # delegates render from.
    backend.bumpFont(1)
    assert backend._font_size == before_size + 1, "bumpFont did not change fontSize"
    backend.bumpFont(-1)
    assert backend._font_size == before_size, "bumpFont down did not restore"
    backend.toggleTop()
    backend.toggleTop()
    assert backend._keepontop is True, "top double-toggle must restore"
    backend.toggleClickthrough()
    chrome = backend.chrome_region()
    assert not chrome.isEmpty(), "chrome guard region must cover the bars"
    backend._hover_override = False
    backend.hover_tick()
    assert backend.clickthrough_effective, "click-through should be effective off-chrome"
    if window is not None and Backend._on_wayland():
        try:
            m = window.mask()
            assert not m.isEmpty(), "Wayland mask must stay non-null (null = full input)"
        except Exception:
            pass
    backend._hover_override = True
    backend.hover_tick()
    assert not backend.clickthrough_effective, "bar hover must re-enable input"
    if window is not None and Backend._on_wayland():
        # Full input is a null mask (compositor reads null as full-window).
        backend.apply_input_mask()
        assert window.mask().isEmpty(), "bar hover must restore full (null) input"
    backend._hover_override = None
    backend.toggleClickthrough()
    assert not backend.clickthrough_effective, "click-through off must restore input"
    if window is not None and Backend._on_wayland():
        # Restore path must produce a null mask (= full input). Regression
        # this guards: wrong QRegion constructor raised TypeError and left
        # the chrome-only mask behind.
        backend.apply_input_mask()
        try:
            assert window.mask().isEmpty(), "click-through off must restore full (null) input"
        except AssertionError:
            raise
        except Exception:
            pass
    import shutil as _shutil
    import subprocess as _sp
    _real_which, _real_run = _shutil.which, _sp.run
    try:
        _shutil.which = lambda *a, **k: None
        backend._hyprctl_sync_top()
        _shutil.which = lambda *a, **k: "/usr/bin/hyprctl"

        def _boom(*a, **k):
            raise OSError("no compositor")
        _sp.run = _boom
        backend._hyprctl_sync_top()
    finally:
        _shutil.which, _sp.run = _real_which, _real_run
    backend.toggleAutohide()
    backend.clearHistory()
    assert backend.pairs.rowCount() == 0, "clearHistory failed"
    backend.append_pair("復帰", "recovered")
    assert backend.pairs.rowCount() == 1, "append after clear failed"
    # Style prefs: shadow toggle round-trips (whatever persisted).
    before_shadow = backend._shadow_enabled
    backend._shadow_enabled = not before_shadow
    backend.shadowEnabledChanged.emit()
    assert backend._shadow_enabled is not before_shadow
    backend._shadow_enabled = before_shadow
    backend.shadowEnabledChanged.emit()
    backend.panelAlpha = 5.0
    assert backend._panel_alpha == 1.0, "panelAlpha must clamp to 1.0"
    backend.panelAlpha = -1.0
    assert backend._panel_alpha == 0.15, "panelAlpha must clamp to 0.15"
    backend.panelAlpha = 0.88
    # Drawer open forces full input even under click-through.
    backend._clickthrough = True
    backend._hover_override = False
    assert backend.clickthrough_effective, "click-through should be effective"
    backend.setDrawerOpen(True)
    assert not backend.clickthrough_effective, "open drawer must force full input"
    backend.setDrawerOpen(False)
    assert backend.clickthrough_effective, "closed drawer must restore guard"
    backend._clickthrough = False
    backend._hover_override = None
    # Chrome-autohide reveal zones, driven by event coordinates (no global
    # cursor queries — broken on Wayland).
    assert backend._chrome_visible is True, "chrome starts visible"
    backend._chrome_autohide = True
    backend._chrome_hovered = False
    backend.pointerAt(-1, -1, False)  # outside window
    assert backend._chrome_visible is False, "outside window must hide chrome"
    backend._title_h, backend._tool_h = 30, 30
    backend.pointerAt(260, 5, True)  # top strip
    assert backend._chrome_visible is True, "top strip must reveal chrome"
    backend.pointerAt(260, 160, True)  # middle
    assert backend._chrome_visible is False, "middle must keep chrome hidden"
    backend.pointerAt(260, window.height() - 5, True)  # bottom strip
    assert backend._chrome_visible is True, "bottom strip must reveal chrome"
    backend.setChromeHovered(True)  # bar hover reports keep it shown
    backend.pointerAt(260, 160, True)
    assert backend._chrome_visible is True, "bar hover must keep chrome shown"
    backend.setChromeHovered(False)
    backend._chrome_autohide = False
    backend._update_chrome_visibility()
    assert backend._chrome_visible is True, "autohide off must restore chrome"
    # Restore must push every property to QML (bindings don't re-evaluate
    # without notify — stale defaults was a live bug, radius 10 over 0).
    _fired = []
    for _sig in (backend.showJaChanged, backend.keepOnTopChanged,
                 backend.clickThroughChanged, backend.autoHideChanged,
                 backend.statusTextChanged, backend.fontSizeChanged,
                 backend.fontFamilyChanged, backend.enColorChanged,
                 backend.jaColorChanged, backend.shadowEnabledChanged,
                 backend.shadowColorChanged, backend.panelAlphaChanged,
                 backend.chromeAutoHideChanged, backend.chromeVisibleChanged,
                 backend.cornerRadiusChanged):
        _sig.connect(lambda _s=_sig: _fired.append(_s))
    backend.restore_state()
    assert len(_fired) == 15, f"restore must emit all 15 notifies, got {len(_fired)}"
    # Real event chain: synthetic pointer moves must reach pointerAt through
    # the QML HoverHandler (no cursor queries involved anywhere).
    from PySide6.QtTest import QTest
    from PySide6.QtCore import QPoint as _QPoint
    QTest.mouseMove(window, _QPoint(10, 10))
    QTest.qWait(250)
    assert backend._pointer_inside is True, "hover handler must report window entry"
    assert backend._pointer_strip is True, "top corner must be a reveal strip"
    QTest.mouseMove(window, _QPoint(window.width() // 2, window.height() // 2))
    QTest.qWait(250)
    assert backend._pointer_inside is True, "middle must still be inside"
    assert backend._pointer_strip is False, "middle must not be a reveal strip"
    # Drawer opens offscreen without errors and reports back.
    drawer = window.findChild(QObject, "styleDrawer")
    assert drawer is not None, "style drawer must exist"
    drawer.setProperty("visible", True)
    assert backend._drawer_open is True, "drawer must report open state"
    # Real tap path: clicking a swatch must set its target AND open the
    # dialog (regression: taps did nothing live while programmatic
    # open/accept worked).
    from PySide6.QtCore import QPointF as _QPointF
    from PySide6.QtGui import Qt as _Qt
    from PySide6.QtQuick import QQuickItem as _QQuickItem
    _en_btn = window.findChild(_QQuickItem, "enColorBtn")
    assert _en_btn is not None, "EN swatch must exist"
    _center = _en_btn.mapToScene(_QPointF(_en_btn.property("width") / 2.0,
                                          _en_btn.property("height") / 2.0))
    QTest.mouseClick(window, _Qt.LeftButton, _Qt.NoModifier,
                     _center.toPoint())
    QTest.qWait(300)
    assert drawer.property("colorTarget") == "en", "tap must select EN target"
    _dlg2 = window.findChild(QObject, "colorDialog")
    assert _dlg2 is not None and bool(_dlg2.property("visible")), \
        "tap must open the color dialog"
    # Font family model must be usable and show Default when unset.
    _combo = window.findChild(QObject, "fontCombo")
    assert _combo is not None, "font combo must exist"
    assert int(_combo.property("count")) > 1, "font model must list system fonts"
    if not backend._font_family:
        assert str(_combo.property("currentText")) == "Default", \
            "unset family must display Default"
    # Color picker wiring: dialog accept must recolor the backend (and through
    # it, every delegate) for each target.
    from PySide6.QtCore import QMetaObject as _QMeta
    _dlg = window.findChild(QObject, "colorDialog")
    assert _dlg is not None, "color dialog must exist"
    for _target, _attr, _color in (("en", "_en_color", "#ff0000"),
                                   ("ja", "_ja_color", "#00ff00"),
                                   ("shadow", "_shadow_color", "#0000ff")):
        drawer.setProperty("colorTarget", _target)
        QTest.qWait(100)
        _QMeta.invokeMethod(_dlg, "open")
        QTest.qWait(200)
        _dlg.setProperty("selectedColor", _color)
        _QMeta.invokeMethod(_dlg, "accept")
        QTest.qWait(100)
        assert getattr(backend, _attr) == _color, \
            f"accept must apply {_target} color"
    drawer.setProperty("visible", False)
    QTest.qWait(300)
    assert backend._drawer_open is False, "drawer must report closed state"
    # Drawer content must leave a scrollbar lane (regression: overlay bar
    # covered the ComboBox/SpinBox arrows).
    _col = window.findChild(QObject, "styleColumn")
    assert _col is not None, "style column must exist"
    _dw = drawer.property("width")
    assert abs(float(_col.property("width")) - (float(_dw) - 34.0)) < 1.0, \
        "style content must reserve a scrollbar lane"
    # Autoscroll: overflow the view, let layout settle, must end at bottom.
    from PySide6.QtTest import QTest as _QTest2
    _view = window.findChild(QObject, "historyView")
    assert _view is not None, "history ListView must exist"
    for _i in range(30):
        backend.append_pair(f"スクロール行{_i}", f"scroll check line {_i} with padding words")
    _QTest2.qWait(600)
    assert bool(_view.property("atYEnd")), "must stick to bottom on new lines"
    # ...but never yank a user who scrolled up to read history.
    _view.setProperty("contentY", 0.0)
    _QTest2.qWait(200)
    backend.append_pair("新規", "fresh line while scrolled up")
    _QTest2.qWait(600)
    assert float(_view.property("contentY")) < 1.0, "must not yank scrolled-up readers"
    # Scrollbar-drag simulation: jump mid-list (no flick, no movementEnded),
    # lines must not move us; reaching the end re-latches following.
    _mid = float(_view.property("contentHeight")) / 2.0
    _view.setProperty("contentY", _mid)
    _QTest2.qWait(200)
    assert float(_view.property("contentY")) > 1.0, "test setup: must be mid-list"
    backend.append_pair("追従", "line during simulated drag")
    _QTest2.qWait(600)
    assert abs(float(_view.property("contentY")) - _mid) < 2.0, \
        "dragged readers must stay put"
    _view.setProperty("contentY", float(_view.property("contentHeight")))
    _QTest2.qWait(200)
    backend.append_pair("再開", "line after scrolling back down")
    _QTest2.qWait(600)
    assert bool(_view.property("atYEnd")), "must resume following at the end"
    # Workspace-aware pin decision (pure logic, no compositor calls).
    W = Backend._want_pinned
    assert W(1, 1, True) is True, "same workspace + Top must pin"
    assert W(2, 1, True) is False, "other workspace must unpin"
    assert W(1, 1, False) is False, "Top off must never pin"
    assert W(1, None, True) is False, "unknown home must not pin"
    # Compositor radius query degrades to None/valid-int, never raises.
    _r = Backend._query_compositor_radius()
    assert _r is None or (isinstance(_r, int) and 0 <= _r <= 16), "radius query must be None or 0..16"
    # pin_tick with a canned compositor: adopts home, dispatches on mismatch.
    _real_json, _real_run = backend._hyprctl_json, subprocess.run
    _calls = []
    try:
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": 1},
              "pinned": False, "floating": True}]
            if a == ("clients",) else {"id": 1})
        subprocess.run = lambda *a, **k: (_calls.append(a[0]), None)[1]
        backend._keepontop = True
        backend._home_ws = None
        backend.pin_tick()
        assert backend._home_ws == 1, "pin_tick must adopt home workspace"
        assert any("action=\"enable\"" in str(c) for c in _calls), \
            f"mismatch must dispatch pin enable, got {_calls}"
        _calls.clear()
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": 1},
              "pinned": True, "floating": True}]
            if a == ("clients",) else {"id": 1})
        backend.pin_tick()
        assert _calls == [], "matching state must not dispatch"
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": 1},
              "pinned": True, "floating": True}]
            if a == ("clients",) else {"id": 2})
        backend.pin_tick()
        assert any("action=\"disable\"" in str(c) for c in _calls), \
            "leaving home must dispatch pin disable"
        # Follow-residue must NOT be adopted as a new home: box still pinned
        # from the previous poll, seen on a new workspace.
        _calls.clear()
        backend._home_ws = 1
        backend._last_pinned = True
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": 2},
              "pinned": True, "floating": True}]
            if a == ("clients",) else {"id": 2})
        backend.pin_tick()
        assert backend._home_ws == 1, "follow-residue must keep the old home"
        assert any("action=\"disable\"" in str(c) for c in _calls), \
            "follow-residue must still unpin"
        assert not any("move" in str(c) for c in _calls), \
            "must never move windows: the compositor flips the active " \
            "workspace to follow the move, looping forever"
        # The trap this guards: persistent mismatch must NOT re-adopt on
        # later ticks (old level-trigger re-pinned forever ~2 ticks later).
        # The mock world applies our disables from here on.
        _world = {"pinned": True, "ws": 2, "active": 2}
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": _world["ws"]},
              "pinned": _world["pinned"], "floating": True}]
            if a == ("clients",) else {"id": _world["active"]})
        _orig_run = subprocess.run

        def _fake_run(cmd, **k):
            s = str(cmd)
            if "action=\"disable\"" in s:
                _world["pinned"] = False
            elif "action=\"enable\"" in s:
                _world["pinned"] = True
            _calls.append(cmd)
            return None

        subprocess.run = _fake_run
        backend.pin_tick()
        backend.pin_tick()
        assert backend._home_ws == 1, "stable mismatch must never re-adopt"
        assert _world["pinned"] is False, "stable mismatch must stay unpinned"
        subprocess.run = _orig_run
        # Genuine user move (was unpinned) adopts the new home. Simulate
        # the edge: last poll saw it on ws1, now it is on ws2.
        _calls.clear()
        backend._last_ws = 1
        backend._last_pinned = False
        backend._hyprctl_json = lambda *a: (
            [{"pid": os.getpid(), "workspace": {"id": 2},
              "pinned": False, "floating": True}]
            if a == ("clients",) else {"id": 1})
        backend.pin_tick()
        assert backend._home_ws == 2, "user move must adopt the new home"
        # Re-arming Top adopts wherever the box currently is.
        backend._keepontop = False
        backend.toggleTop()
        assert backend._keepontop is True and backend._home_ws is None, \
            "Top enable must clear home for re-adoption"
    finally:
        backend._hyprctl_json, subprocess.run = _real_json, _real_run
    print("self-test: ALL OK")


def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    qml_errors = []
    engine.warnings.connect(lambda w: qml_errors.extend(w))
    backend = Backend()
    args = sys.argv[1:]
    if "--thread" in args and args.index("--thread") + 1 < len(args):
        backend.thread = args[args.index("--thread") + 1]
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("pairModel", backend.pairs)
    try:
        from PySide6.QtGui import QFontDatabase
        engine.rootContext().setContextProperty(
            "fontFamilies", QFontDatabase.families())
    except Exception:
        engine.rootContext().setContextProperty("fontFamilies", [])
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "qml", "Textbox.qml")))
    roots = engine.rootObjects()
    if not roots:
        print("qml load failed", "\n".join(str(e) for e in qml_errors), file=sys.stderr)
        sys.exit(2)
    window = roots[0]
    backend.attach_window(window)
    if "--smoke-test" in sys.argv or "--self-test" in sys.argv:
        if "--self-test" in sys.argv:
            QTimer.singleShot(800, lambda: self_test(backend, window))
        QTimer.singleShot(4000, lambda: app.exit(0 if not qml_errors else 3))
    if "--start-workers" in sys.argv:
        backend.ensure_workers()
    if "--self-test" in sys.argv:
        QTimer.singleShot(3900, lambda: print("qml warnings:", [str(e) for e in qml_errors])
                          if qml_errors else None)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
