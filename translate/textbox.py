#!/usr/bin/env python3
"""textbox.py v4 — Luna-style translation readout (frameless, toolbar, themes).
Scrolling JA/EN history; modes EN-only / JA+EN; keep-on-top, click-through,
auto-disappear, copy, re-translate; geometry + prefs persist via QSettings.
Embedded pipeline: hook thread -> translator thread -> main-thread display.
Design follows LunaTranslator's TranslatorWindow (frameless resizable,
ShowWithoutActivating, toolbar toggles, hover-aware click-through, auto-hide);
Windows-only parts (NativeUtils, Magpie, TTS, furigana, game-follow) excluded.
Platform notes: click-through is done via Qt.WindowTransparentForInput, which
DOES work on Wayland with Qt 6 (verified at the protocol level: Qt sends an
empty wl_surface input region, so the compositor routes clicks to the window
below). QWindow.setMask() alone cannot do it — Qt normalizes every empty mask
to null, which the compositor reads as "full input". Hover transitions must
not touch window flags (setWindowFlags destroys/recreates the Wayland
surface — the crash recipe), so the hover guard only swaps the input mask
between full-window and bars-only. Qt.WindowStaysOnTopHint alone cannot hold
a window above a game on tiling Wayland compositors, so on Hyprland the Top
toggle also floats + pins the window (hyprctl, best-effort).
Usage: textbox.py [--smoke-test] [--self-test] [--start-workers] [--thread NAME|NUM|*]
  --thread selects the vn-bridge v2 thread (* = follow Textractor's selection).
"""
import os
import shutil
import subprocess
import sys
import threading
import time
from collections import deque

from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QCursor, QGuiApplication, QRegion, QTextCursor
from PySide6.QtWidgets import (QApplication, QHBoxLayout, QLabel, QMainWindow,
                               QPushButton, QSizePolicy, QTextEdit, QVBoxLayout,
                               QWidget, QSizeGrip)

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cfg import load_config
CONFIG = load_config()
ORG, APP = "vn-translate", "textbox"

THEME = """
QMainWindow { background: transparent; }
#panel { background: rgba(28, 28, 32, 225); border-radius: 10px; }
#titlebar { background: rgba(48, 48, 56, 225);
  border-top-left-radius: 10px; border-top-right-radius: 10px; }
#titlebar QLabel { color: #cfcfcf; }
#titlebar QPushButton, #toolbar QPushButton {
  background: transparent; color: #cfcfcf; border: none;
  padding: 3px 7px; border-radius: 5px; font-size: 12px; }
#titlebar QPushButton:hover, #toolbar QPushButton:hover { background: rgba(255,255,255,28); }
#titlebar QPushButton:checked, #toolbar QPushButton:checked,
#titlebar QPushButton[active="true"], #toolbar QPushButton[active="true"] {
  background: rgba(127,179,255,60); color: #ffffff; }
#toolbar { background: rgba(40, 40, 46, 225);
  border-bottom-left-radius: 10px; border-bottom-right-radius: 10px; }
QTextEdit { background: transparent; border: none; color: #f0f0f0; }
#status { color: #9a9a9a; font-size: 11px; }
"""


class Textbox(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("vn-translate")
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_ShowWithoutActivating)
        self.history = deque(maxlen=200)
        self.pending = deque()
        self.ja_queue = deque()
        self.translator = None
        self.last_ja = ""
        self.show_ja = True
        self.keepontop = True
        self.clickthrough = False
        self.autohide = False
        self.autohide_delay = 4
        self.last_text_time = time.time()
        self._dragpos = None
        self._hover_override = None  # self-test hook: forces chrome_hovered()

        panel = QWidget(objectName="panel")
        lay = QVBoxLayout(panel)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.setSpacing(0)

        # slim custom titlebar (drag handle + window buttons)
        titlebar = QWidget(objectName="titlebar")
        tl = QHBoxLayout(titlebar)
        tl.setContentsMargins(8, 2, 4, 2)
        self.title_label = QLabel("vn-translate")
        self.top_btn = QPushButton("Top")
        self.top_btn.setCheckable(True)
        self.top_btn.setToolTip("Keep on top (Hyprland: also pins the window)")
        self.top_btn.clicked.connect(self.toggle_top)
        self.click_btn = QPushButton("Click")
        self.click_btn.setCheckable(True)
        self.click_btn.setToolTip("Click-through (hover either bar to click)")
        self.click_btn.clicked.connect(self.toggle_clickthrough)
        self.min_btn = QPushButton("_")
        self.min_btn.setToolTip("Minimize")
        self.min_btn.clicked.connect(self.showMinimized)
        self.close_btn = QPushButton("x")
        self.close_btn.clicked.connect(self.close)
        for w in (self.title_label,):
            tl.addWidget(w)
        tl.addStretch(1)
        for w in (self.top_btn, self.click_btn, self.min_btn, self.close_btn):
            tl.addWidget(w)
        titlebar.mousePressEvent = self._drag_start
        titlebar.mouseMoveEvent = self._drag_move
        lay.addWidget(titlebar)
        self.titlebar = titlebar

        self.view = QTextEdit()
        self.view.setReadOnly(True)
        self.view.setTextInteractionFlags(Qt.TextSelectableByMouse | Qt.TextSelectableByKeyboard)
        lay.addWidget(self.view, 1)

        # function toolbar (Luna button-bar style)
        toolbar = QWidget(objectName="toolbar")
        bl = QHBoxLayout(toolbar)
        bl.setContentsMargins(6, 2, 6, 4)
        self.mode_btn = QPushButton("JA+EN")
        self.mode_btn.setToolTip("Toggle: translation only / original + translation")
        self.mode_btn.clicked.connect(self.toggle_mode)
        self.retrans_btn = QPushButton("Re")
        self.retrans_btn.setToolTip("Re-translate last line")
        self.retrans_btn.clicked.connect(self.retranslate)
        self.copy_btn = QPushButton("Copy")
        self.copy_btn.setToolTip("Copy selection, else last translation")
        self.copy_btn.clicked.connect(self.copy_current)
        self.hide_btn = QPushButton("Auto")
        self.hide_btn.setCheckable(True)
        self.hide_btn.setToolTip("Auto-disappear after delay, reappear on new text")
        self.hide_btn.clicked.connect(self.toggle_autohide)
        self.font_down = QPushButton("A-")
        self.font_up = QPushButton("A+")
        self.font_down.clicked.connect(lambda: self.bump_font(-1))
        self.font_up.clicked.connect(lambda: self.bump_font(1))
        self.clear_btn = QPushButton("Clear")
        self.clear_btn.clicked.connect(self.clear_history)
        self.status = QLabel("● stopped", objectName="status")
        for w in (self.mode_btn, self.retrans_btn, self.copy_btn, self.hide_btn,
                  self.font_down, self.font_up, self.clear_btn):
            bl.addWidget(w)
        bl.addWidget(self.status)
        grip = QSizeGrip(toolbar)
        bl.addWidget(grip)
        lay.addWidget(toolbar)
        self.toolbar = toolbar

        self.setCentralWidget(panel)
        self.resize(520, 320)
        self.setStyleSheet(THEME)
        self.restore_state()
        self.apply_flags(initial=True)

        self.drain_timer = QTimer()
        self.drain_timer.timeout.connect(self.drain)
        self.drain_timer.start(120)
        self.status_timer = QTimer()
        self.status_timer.timeout.connect(self.poll_status)
        self.status_timer.start(2000)
        self.hover_timer = QTimer()
        self.hover_timer.timeout.connect(self.hover_tick)
        self.hover_timer.start(100)
        self.hide_timer = QTimer()
        self.hide_timer.timeout.connect(self.hide_tick)
        self.hide_timer.start(500)

    # ---- window flags / input region ----
    @staticmethod
    def _on_wayland():
        try:
            return QGuiApplication.platformName() == "wayland"
        except Exception:
            return False

    def apply_flags(self, initial=False):
        # TransparentForInput is the click-through mechanism on BOTH X11 and
        # Wayland (protocol-verified on Qt 6.11: empty wl input region).
        # On Wayland it follows the mode (not the hover state) so hover
        # transitions never recreate the surface; the hover guard instead
        # swaps the input mask (cheap, surface-preserving). On X11 the mask
        # would also clip the visuals, so X11 keeps the old flag-follows-hover
        # behavior (surface recreation is cheap and safe there).
        if self._on_wayland():
            want_transparent = self.clickthrough
        else:
            want_transparent = self.clickthrough_effective
        flags = (Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
                 if self.keepontop else Qt.FramelessWindowHint | Qt.Tool)
        if want_transparent:
            flags |= Qt.WindowTransparentForInput
        # Only recreate the native window when the flag set actually changed:
        # setWindowFlags destroys/recreates the Wayland surface, and doing it
        # in a busy timer loop is the crash recipe (hard surface error).
        if initial or int(flags) != getattr(self, "_flags_applied", None):
            self._flags_applied = int(flags)
            self.setWindowFlags(flags)
            if initial or not self.isHidden():
                self.show()
        self.apply_input_mask()
        self.top_btn.setChecked(self.keepontop)
        self.click_btn.setChecked(self.clickthrough)

    def chrome_region(self):
        """Input region covering just the titlebar + toolbar (window coords).
        Used as the click-through guard: bars stay clickable so Top/Click and
        drag remain reachable while everything else falls through."""
        region = QRegion()
        for bar in (self.titlebar, self.toolbar):
            try:
                origin = bar.mapTo(self, bar.rect().topLeft())
                region |= QRegion(origin.x(), origin.y(),
                                  bar.width(), bar.height())
            except Exception:
                pass
        return region

    def apply_input_mask(self):
        """Wayland hover guard for click-through mode.

        click-through OFF -> full-window input. ON + bar hovered -> full
        input (clicks work). ON + elsewhere -> bars-only input (clicks on the
        text area fall through to the game; bars stay clickable so the mode
        can be toggled back off). No-op on X11, where the flag in
        apply_flags() already covers it and a mask would clip the visuals.
        """
        if not self._on_wayland():
            return
        handle = self.windowHandle()
        if handle is None:
            return  # pre-show: next hover_tick applies it once mapped
        if self.clickthrough_effective:
            want = self.chrome_region()
            if want.isEmpty():
                want = QRegion(self.rect())  # fail safe: input on
            key = ("chrome", want.boundingRect().getRect())
        else:
            want = QRegion(self.rect())
            key = ("full", want.boundingRect().getRect())
        if key != getattr(self, "_mask_applied", None):
            self._mask_applied = key
            handle.setMask(want)

    @property
    def clickthrough_effective(self):
        return self.clickthrough and not self.chrome_hovered()

    def chrome_hovered(self):
        """True when the cursor is over either bar, so Top/Click/drag stay
        reachable while click-through is on. (The old toolbar-only guard left
        the titlebar — i.e. the Click button itself — unclickable.)"""
        if self._hover_override is not None:
            return self._hover_override
        try:
            pos = QCursor.pos()
            for bar in (self.titlebar, self.toolbar):
                if bar.rect().contains(bar.mapFromGlobal(pos)):
                    return True
            return False
        except Exception:
            return True

    def hover_tick(self):
        # Re-apply only on transitions to avoid window recreation churn.
        want = self.clickthrough_effective
        if want != getattr(self, "_ct_applied", None):
            self._ct_applied = want
            self.apply_flags()

    def hide_tick(self):
        if not self.autohide or self.isHidden():
            return
        if time.time() - self.last_text_time < self.autohide_delay:
            return
        try:
            if self.geometry().contains(QCursor.pos()):
                self.last_text_time = time.time()
                return
        except Exception:
            pass
        self.hide()

    def toggle_top(self):
        self.keepontop = not self.keepontop
        self.apply_flags()
        self._hyprctl_sync_top_deferred()

    def toggle_clickthrough(self):
        self.clickthrough = not self.clickthrough
        self._ct_applied = None  # force re-apply on next tick
        self._mask_applied = None
        self.apply_flags()  # one surface recreation per toggle (user action)
        if self.keepontop:
            # Toggling the flag may recreate the Wayland surface, which drops
            # the compositor-side pin — re-sync so Top keeps holding (deferred:
            # the new surface maps asynchronously, an immediate dispatch would
            # hit the old, dying window).
            self._hyprctl_sync_top_deferred()

    def _hyprctl_sync_top_deferred(self):
        self._hyprctl_sync_top()
        if self.keepontop:
            QTimer.singleShot(500, self._hyprctl_sync_top)
            QTimer.singleShot(1500, self._hyprctl_sync_top)
        else:
            QTimer.singleShot(500, self._hyprctl_sync_top)

    def _hyprctl_sync_top(self):
        """Mirror keep-on-top into the compositor. Qt's StaysOnTopHint is
        only a hint on Wayland — Hyprland restacks floating windows on focus,
        so without this the game covers the textbox on the first click.
        Enabling also floats the window (pin requires floating; Top semantics
        need a floating overlay anyway). Best-effort: silently skips when not
        on Hyprland or hyprctl fails."""
        if not shutil.which("hyprctl"):
            return
        if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return
        sel = 'window="title:^vn-translate$"'
        cmds = [
            ["hyprctl", "dispatch",
             f'hl.dsp.window.float({{window="title:^vn-translate$", action="enable"}})'],
            ["hyprctl", "dispatch",
             f'hl.dsp.window.pin({{{sel}, action="enable"}})'],
            ["hyprctl", "dispatch",
             f'hl.dsp.window.bring_to_top({{{sel}}})'],
        ] if self.keepontop else [
            ["hyprctl", "dispatch",
             f'hl.dsp.window.pin({{{sel}, action="disable"}})'],
        ]
        for cmd in cmds:
            try:
                subprocess.run(cmd, capture_output=True, timeout=5)
            except Exception:
                pass

    def toggle_autohide(self):
        self.autohide = not self.autohide
        self.hide_btn.setChecked(self.autohide)
        self.last_text_time = time.time()

    def _drag_start(self, ev):
        if ev.button() == Qt.LeftButton:
            self._dragpos = ev.globalPosition().toPoint() - self.frameGeometry().topLeft()

    def _drag_move(self, ev):
        if self._dragpos is not None and ev.buttons() & Qt.LeftButton:
            self.move(ev.globalPosition().toPoint() - self._dragpos)

    # ---- persistence ----
    def restore_state(self):
        from PySide6.QtCore import QSettings
        s = QSettings(ORG, APP)
        g = s.value("geometry")
        if g:
            self.restoreGeometry(g)
        self.show_ja = s.value("show_ja", True, type=bool)
        self.mode_btn.setText("JA+EN" if self.show_ja else "EN-only")
        self.view.setFontPointSize(float(s.value("fontsize", 11)))
        self.keepontop = s.value("keepontop", True, type=bool)
        self.autohide = s.value("autohide", False, type=bool)
        self.hide_btn.setChecked(self.autohide)

    def closeEvent(self, ev):
        from PySide6.QtCore import QSettings
        s = QSettings(ORG, APP)
        s.setValue("geometry", self.saveGeometry())
        s.setValue("show_ja", self.show_ja)
        s.setValue("fontsize", self.view.fontPointSize())
        s.setValue("keepontop", self.keepontop)
        s.setValue("autohide", self.autohide)
        super().closeEvent(ev)

    # ---- content ----
    def toggle_mode(self):
        self.show_ja = not self.show_ja
        self.mode_btn.setText("JA+EN" if self.show_ja else "EN-only")
        self.rerender()

    def bump_font(self, delta):
        self.view.setFontPointSize(max(8, self.view.fontPointSize() + delta))

    def clear_history(self):
        self.history.clear()
        self.view.clear()

    def copy_current(self):
        sel = self.view.textCursor().selectedText()
        QApplication.clipboard().setText(sel or (self.history[-1][1] if self.history else ""))

    def retranslate(self):
        if self.history:
            self.ja_queue.append(self.history[-1][0])
            self.last_ja = ""  # bypass dedup

    def rerender(self):
        self.view.clear()
        for ja, en in self.history:
            self.append_pair(ja, en, record=False)

    def append_pair(self, ja, en, record=True):
        import html as _html
        if record:
            self.history.append((ja, en))
        ja, en = _html.escape(ja or ""), _html.escape(en or "")
        # PySide6 (6.11 strict enums): the cursor-move enum is
        # QTextCursor.MoveOperation.End — the PyQt5-style `cur.End` shorthand
        # raises AttributeError and silently kills every rendered line.
        self.view.moveCursor(QTextCursor.MoveOperation.End)
        if self.show_ja and ja:
            self.view.insertHtml(f'<div style="color:#9a9a9a; font-size:small;">{ja}</div>')
        self.view.insertHtml(f'<div>{en}</div><div style="height:6px;"></div>')
        self.view.moveCursor(QTextCursor.MoveOperation.End)
        self.view.ensureCursorVisible()
        self.last_text_time = time.time()
        if self.isHidden():
            self.show()

    # ---- pipeline ----
    def ensure_workers(self):
        if self.translator is not None:
            return
        try:
            import vn_translate
            self.translator = vn_translate.make_translator(True)
        except Exception as e:
            self.status.setText(f"translator init failed: {e}")
            return
        threading.Thread(target=self.hook_loop, daemon=True).start()
        threading.Thread(target=self.translate_loop, daemon=True).start()

    def hook_loop(self):
        import time as _time
        from hook_client import listen
        thread = getattr(self, "thread", "*")
        while True:
            try:
                listen(CONFIG.get("hook_url", "ws://localhost:6677"),
                       on_message=self.ja_queue.append, thread=thread)
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
                    self.status.setText(item[1])
                else:
                    ja, out = item
                    self.append_pair(ja, out)
                    self.status.setText("● live")
            except Exception as e:
                # Never let one bad item storm the timer loop (and never die
                # silently when stderr is swallowed by a GUI launcher).
                self.status.setText(f"● display error: {e}")

    def poll_status(self):
        try:
            import websocket
            ws = websocket.create_connection("ws://127.0.0.1:6677", timeout=3)
            ws.close()
            if not self.pending:
                self.status.setText("● live (:6677)")
        except Exception:
            self.status.setText("● stopped")


def self_test(w):
    """Exercise the rendering + interaction paths the plain smoke test
    (window maps) never touches. Any failure here is a real bug."""
    w.append_pair("テスト一行目", "first test line")
    w.append_pair("二行目", "second test line")
    assert len(w.view.toPlainText()) > 10, "append_pair rendered nothing"
    w.toggle_mode()
    w.rerender()
    assert len(w.view.toPlainText()) > 5, "rerender rendered nothing"
    w.retranslate()
    w.copy_current()
    w.toggle_top()
    w.toggle_top()
    w.toggle_clickthrough()
    # Click-through input path: off-chrome => effective; on-chrome => input.
    # The bars-only guard region is pure geometry: testable on any platform.
    chrome = w.chrome_region()
    assert not chrome.isEmpty(), "chrome guard region must cover the bars"
    center = w.view.mapTo(w, w.view.rect().center())
    assert not chrome.contains(center), "guard region must leave the text area open"
    bar_pt = w.titlebar.mapTo(w, w.titlebar.rect().center())
    assert chrome.contains(bar_pt), "guard region must keep the titlebar clickable"
    w._hover_override = False
    w.hover_tick()
    assert w.clickthrough_effective, "click-through should be effective off-chrome"
    h = w.windowHandle()
    if h is not None and w._on_wayland():
        assert not h.mask().isEmpty(), "Wayland mask must stay non-null (null = full input)"
        assert not h.mask().contains(center), "Wayland mask must pass text-area clicks through"
    w._hover_override = True
    w.hover_tick()
    assert not w.clickthrough_effective, "bar hover must re-enable input"
    if h is not None and w._on_wayland():
        assert h.mask().contains(center), "bar hover must restore full input"
    w._hover_override = None
    w.toggle_clickthrough()  # back off
    assert not w.clickthrough_effective, "click-through off must restore input"
    # Hyprland pin sync must never raise: no binary, failing binary, or no
    # compositor must all degrade to a silent skip.
    import shutil as _shutil
    import subprocess as _sp
    _real_which, _real_run = _shutil.which, _sp.run
    try:
        _shutil.which = lambda *a, **k: None
        w._hyprctl_sync_top()
        _shutil.which = lambda *a, **k: "/usr/bin/hyprctl"

        def _boom(*a, **k):
            raise OSError("no compositor")
        _sp.run = _boom
        w._hyprctl_sync_top()
    finally:
        _shutil.which, _sp.run = _real_which, _real_run
    w.toggle_autohide()
    w.bump_font(1)
    w.clear_history()
    assert len(w.view.toPlainText()) == 0 and len(w.history) == 0, "clear_history failed"
    w.append_pair("復帰", "recovered")
    print("self-test: ALL OK")


def main():
    app = QApplication(sys.argv)
    w = Textbox()
    args = sys.argv[1:]
    w.thread = args[args.index("--thread") + 1] if "--thread" in args and args.index("--thread") + 1 < len(args) else "*"
    w.show()
    if "--smoke-test" in sys.argv or "--self-test" in sys.argv:
        if "--self-test" in sys.argv:
            QTimer.singleShot(500, lambda: self_test(w))
        QTimer.singleShot(3000, lambda: app.exit(0))
    if "--start-workers" in sys.argv:
        w.ensure_workers()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
