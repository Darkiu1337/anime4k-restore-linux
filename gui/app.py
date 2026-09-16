#!/usr/bin/env python3
"""anime4k-gui — Qt Quick frontend for the Anime4K Restore launchers.

Thin UI over the scripts/ runners; shares ~/.config/anime4k/games.json
with the `anime4k` TUI. All launch/library/process logic lives in core/;
this file is the QML bootstrap plus the QML-bound backend.
"""
import json
import os
import sys

APP_DIR = os.path.dirname(os.path.realpath(__file__))
REPO_ROOT = os.path.dirname(APP_DIR)
sys.path.insert(0, REPO_ROOT)
from core import paths, store, library, commands, process, system, icons
from core.theme_qt import Theme

from PySide6.QtCore import (QAbstractListModel, QModelIndex, QObject, Qt,
                            QProcess, QProcessEnvironment, QTimer, QUrl,
                            Signal, Slot, Property, qInstallMessageHandler)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

QML_ERRORS = []


def _capture_qt_messages(mode, context, message):
    text = str(message)
    if ".qml:" in text or "TypeError" in text or "ReferenceError" in text \
            or "is not defined" in text:
        QML_ERRORS.append(text)
        sys.stderr.write("[qml] " + text + "\n")
        sys.stderr.flush()


def _log_path():
    d = os.path.expanduser("~/.cache/anime4k")
    try:
        os.makedirs(d, exist_ok=True)
    except OSError:
        return None
    return os.path.join(d, "gui.log")


class GamesModel(QAbstractListModel):
    GidRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    InfoRole = Qt.UserRole + 3
    IconRole = Qt.UserRole + 4

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows = []

    def roleNames(self):
        return {GamesModel.GidRole: b"gid", GamesModel.NameRole: b"name",
                GamesModel.InfoRole: b"info", GamesModel.IconRole: b"icon"}

    def rowCount(self, parent=QModelIndex()):
        return len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        return self._rows[index.row()].get(
            {GamesModel.GidRole: "gid", GamesModel.NameRole: "name",
             GamesModel.InfoRole: "info", GamesModel.IconRole: "icon"}.get(role))

    @Slot()
    def refresh(self):
        self.beginResetModel()
        rows = []
        for gid, g in sorted(store.load_games().items(),
                             key=lambda kv: kv[1].get("name", "")):
            ip = icons.resolve_icon(g.get("runner", ""), g.get("path", ""), gid)
            tr = (g.get("translate") or {}).get("enabled") == "1"
            rows.append({
                "gid": gid,
                "name": g.get("name", gid),
                "info": f"{g.get('runner', '?')}, {g.get('variant', '?')}{', +translate' if tr else ''}",
                "icon": ("file://" + ip) if ip else "",
            })
        self._rows = rows
        self.endResetModel()

    @Slot(str, result=int)
    def index_of(self, gid):
        for i, r in enumerate(self._rows):
            if r["gid"] == gid:
                return i
        return -1


class GuiBackend(QObject):
    statusChanged = Signal()
    bridgeChanged = Signal()
    runningChanged = Signal()
    logAppended = Signal(str)
    logCleared = Signal()
    prompt = Signal(str, str, str)
    threadResults = Signal(str)
    gamesChanged = Signal()

    def __init__(self, model, theme, parent=None):
        super().__init__(parent)
        self._model = model
        self._theme = theme
        self._status = "Idle."
        self._bridge = "○ bridge down"
        self._running = False
        self.proc = None
        self.textbox_proc = None
        self._running_gid = None
        self._running_translate = False
        self._pending = None
        self._timer = QTimer(self)
        self._timer.timeout.connect(self.poll_bridge)
        self._timer.start(3000)
        self.poll_bridge()

    def _get_status(self):
        return self._status

    def _set_status(self, v):
        if v != self._status:
            self._status = v
            self.statusChanged.emit()

    statusText = Property(str, _get_status, _set_status, notify=statusChanged)

    def _get_bridge(self):
        return self._bridge

    bridgeText = Property(str, _get_bridge, notify=bridgeChanged)

    def _get_running(self):
        return self._running

    def _set_running(self, v):
        if v != self._running:
            self._running = v
            self.runningChanged.emit()

    running = Property(bool, _get_running, _set_running, notify=runningChanged)

    @Slot()
    def poll_bridge(self):
        try:
            up = process.translate_bridge_ok()
        except Exception:
            up = False
        txt = "● translation bridge (:6677)" if up else "○ bridge down"
        if txt != self._bridge:
            self._bridge = txt
            self.bridgeChanged.emit()

    @Slot(str, result=str)
    def detect(self, path):
        res = system.detect(path.strip())
        if res is None:
            return ""
        return "|".join(res)

    @Slot(str, result=str)
    def validateGame(self, data_json):
        try:
            return library.validate_entry(json.loads(data_json)) or ""
        except (ValueError, TypeError):
            return "Invalid game data."

    @Slot(str, str, result=str)
    def saveGame(self, gid, data_json):
        try:
            data = json.loads(data_json)
        except (ValueError, TypeError):
            return "Invalid game data."
        reason = library.validate_entry(data)
        if reason:
            return reason
        games = store.load_games()
        if gid:
            prev = games.get(gid, {})
            games[gid] = library.normalize_edit(data, prev)
            store.save_games(games)
        else:
            gid = store.new_game(games, data)
        self._model.refresh()
        self.gamesChanged.emit()
        return ""

    @Slot(str, result=str)
    def gameData(self, gid):
        return json.dumps(store.load_games().get(gid, {}))

    @Slot(str)
    def removeGame(self, gid):
        store.remove_game(gid)
        self._model.refresh()
        self.gamesChanged.emit()

    @Slot(str, result=str)
    def iconFor(self, gid):
        g = store.load_games().get(gid, {})
        ip = icons.resolve_icon(g.get("runner", ""), g.get("path", ""), gid)
        return ("file://" + ip) if ip else ""

    @Slot(str, result=str)
    def gameDetails(self, gid):
        g = store.load_games().get(gid, {})
        if not g:
            return "Select a game."
        tr = g.get("translate", {})
        tr_txt = ""
        if tr.get("enabled") == "1":
            tr_txt = (f"Translation: on ({tr.get('hook_code') or 'hook auto-detect'})"
                      + (f", thread {tr.get('thread')}" if tr.get("thread") else "")
                      + "<br>")
        return (
            f"<b>{g.get('name', gid)}</b><br>"
            f"Runner: {g.get('runner', '?')} &nbsp; Variant: {g.get('variant', '?')}<br>"
            f"GPU: {g.get('gpu', '?')} &nbsp; FPS cap: {g.get('fps', '?')} &nbsp; "
            f"Overlay: {'on' if g.get('hud') == '1' else 'off'}<br>"
            + (f"Prefix: {g.get('prefix_mode', 'shared')}<br>" if g.get("runner") == "proton" else "")
            + (f"Language: {g.get('lang')}<br>" if g.get("lang") else "")
            + tr_txt
            + f"Path: {g.get('path', '?')}")

    @Slot(result="QVariant")
    def listVariants(self):
        return system.list_variants() or ["L"]

    @Slot(str, result=str)
    def variantNote(self, v):
        return paths.VARIANT_NOTES.get(v, "")

    @Slot(result="QVariant")
    def listGpus(self):
        return system.list_gpus()

    @Slot(result=str)
    def runnersJson(self):
        return json.dumps(paths.RUNNERS)

    @Slot(result="QVariant")
    def locales(self):
        return ["System default"] + list(paths.LOCALES)

    @Slot(QUrl, result=str)
    def fileUrlToPath(self, url):
        try:
            return url.toLocalFile()
        except Exception:
            return ""

    @Slot(str, result=QUrl)
    def pathToFileUrl(self, path):
        try:
            return QUrl.fromLocalFile(path)
        except Exception:
            return QUrl()

    @Slot(str, result=bool)
    def isDir(self, path):
        return os.path.isdir(path.strip())

    @Slot(result=str)
    def homeDir(self):
        return os.path.expanduser("~")

    @Slot(result=str)
    def mediaDir(self):
        return f"/run/media/{os.environ.get('USER', '')}"

    @Slot(str, result=str)
    def lastDir(self):
        d = store.load_config().get("gui.last_dir", os.path.expanduser("~"))
        return d if os.path.isdir(d) else os.path.expanduser("~")

    @Slot(str)
    def rememberDir(self, path):
        cfg = store.load_config()
        cfg["gui.last_dir"] = path if os.path.isdir(path) else os.path.dirname(path)
        store.save_config(cfg)

    @Slot(str, bool, result=str)
    def launchGame(self, gid, unfiltered):
        game = store.load_games().get(gid)
        if not game:
            return "Unknown game."
        if not os.path.exists(game.get("path", "")):
            return f"Path no longer exists:\n{game['path']}"
        if self.proc is not None:
            return "A game is already running."
        if process.find_strays(process.stray_token(game)):
            mode = "unfiltered" if unfiltered else "filtered"
            self._pending = ("launch", gid, unfiltered)
            self.emit_prompt("Stale game processes",
                             f"Leftover processes of '{game.get('name', gid)}' are still "
                             f"running.\nLaunching {mode} now would attach to them "
                             f"instead of starting fresh.",
                             ["Kill && Launch", "Launch anyway", "Cancel"])
            return "pending"
        return self._start_game(gid, game, unfiltered)

    def _start_game(self, gid, game, unfiltered):
        import datetime
        argv = commands.build_command(game)
        env = QProcessEnvironment.systemEnvironment()
        if unfiltered:
            for var in paths.VKBASALT_ENV_VARS:
                env.remove(var)
            env.insert("DISABLE_VKBASALT", "1")
        stamp = datetime.datetime.now().strftime("%H:%M:%S")
        mode = "unfiltered A/B" if unfiltered else f"filtered ({game.get('variant', '')})"
        self.logCleared.emit()
        self.logAppended.emit(f"[{stamp}] {game.get('name', gid)} — {mode}")
        self.logAppended.emit(f"$ {' '.join(argv)}\n")
        self.proc = QProcess(self)
        self.proc.setProgram(argv[0])
        self.proc.setArguments(argv[1:])
        self.proc.setProcessEnvironment(env)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self._read_log)
        self.proc.finished.connect(self._finished)
        self.proc.start()
        if not self.proc.waitForStarted(10000):
            self.proc = None
            return "Failed to start the launcher script."
        self._set_status(f"Running {game.get('name', '')} — {mode}…")
        self._set_running(True)
        self._running_gid = gid
        self._running_translate = False
        return ""

    @Slot(str, bool, result=str)
    def translateGame(self, gid, setup):
        game = store.load_games().get(gid)
        if not game:
            return "Unknown game."
        if game.get("runner") != "proton":
            return "Translation needs a Proton/Windows game."
        if game.get("translate", {}).get("enabled") != "1":
            return "Enable translation for this game first (Edit…)."
        if not setup and not (game.get("translate", {}).get("hook_code") or "").strip():
            self._pending = ("translate", gid, True)
            self.emit_prompt("No hook recorded",
                             "No hook code is recorded for this game yet.\n"
                             "Launch Setup (Textractor visible) to pick the story thread?",
                             ["Launch Setup…", "Cancel"])
            return "pending"
        if not os.path.exists(game.get("path", "")):
            return f"Path no longer exists:\n{game['path']}"
        if self.proc is not None:
            return "A game is already running."
        if process.translate_bridge_ok():
            self._pending = ("translate", gid, setup)
            self.emit_prompt("Translation session live",
                             "A translation session is already running.\n"
                             "Replace it with a fresh launch, or open the Textbox?",
                             ["Stop && Launch new", "Open Textbox", "Cancel"])
            return "pending"
        if process.translate_wedge_pids(game.get("path", "")):
            self._pending = ("translate", gid, setup)
            self.emit_prompt("Wedged translation session",
                             "A previous translation container is stuck (no game running, "
                             "prefix held).\nNew launches stall behind it until cleared.",
                             ["Clear && Launch", "Cancel"])
            return "pending"
        if process.find_strays(process.stray_token(game)):
            self._pending = ("translate", gid, setup)
            self.emit_prompt("Stale game processes",
                             f"Leftover processes of '{game.get('name', gid)}' are still "
                             f"running.\nA translation launch would stall behind them.",
                             ["Kill && Launch", "Launch anyway", "Cancel"])
            return "pending"
        return self._start_translate(gid, game, setup)

    def _start_translate(self, gid, game, setup):
        import datetime
        argv = commands.build_translate_command(game, gid, setup)
        env = QProcessEnvironment.systemEnvironment()
        stamp = datetime.datetime.now().strftime("%H:%M:%S")
        self.logCleared.emit()
        mode = "setup (pick the story thread in Textractor)" if setup else "filtered + translation"
        self.logAppended.emit(f"[{stamp}] {game.get('name', gid)} — {mode}")
        self.logAppended.emit(f"$ {' '.join(argv)}\n")
        self.proc = QProcess(self)
        self.proc.setProgram(argv[0])
        self.proc.setArguments(argv[1:])
        self.proc.setProcessEnvironment(env)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self._read_log)
        self.proc.finished.connect(self._finished)
        self.proc.start()
        if not self.proc.waitForStarted(10000):
            self.proc = None
            return "Failed to start the translation launcher."
        self._set_status(f"Running {game.get('name', '')} — {mode}…")
        self._set_running(True)
        self._running_gid = gid
        self._running_translate = True
        self.openTextbox(gid)
        return ""

    @Slot(int)
    def resolvePrompt(self, idx):
        pending, self._pending = self._pending, None
        if pending is None:
            return
        kind, gid, extra = pending
        game = store.load_games().get(gid)
        if game is None:
            return
        if kind == "launch":
            if idx == 0:
                self.logAppended.emit("cleaned stray processes.")
                process.kill_strays(process.stray_token(game))
                err = self._start_game(gid, game, extra)
            elif idx == 1:
                err = self._start_game(gid, game, extra)
            else:
                return
            if err:
                self.logAppended.emit(err)
        elif kind == "translate":
            if idx < 0:
                return
            btn = idx
            if self._last_prompt_title == "Translation session live":
                if btn == 1:
                    self.openTextbox(gid)
                    return
                if btn != 0:
                    return
                self.logAppended.emit("stopping live session for relaunch…")
                self._set_status("Stopping live session…")
                process.stop_session(game["path"])
                self.logAppended.emit("stopped.")
            elif self._last_prompt_title == "Wedged translation session":
                if btn != 0:
                    return
                self.logAppended.emit("clearing wedged session…")
                self._set_status("Clearing wedged session…")
                process.stop_session(game["path"])
                self.logAppended.emit("cleared.")
            elif self._last_prompt_title == "No hook recorded":
                if btn != 0:
                    return
                extra = True
            elif self._last_prompt_title == "Stale game processes":
                if btn == 0:
                    self.logAppended.emit("cleaned stray processes.")
                    process.kill_strays(process.stray_token(game))
                elif btn != 1:
                    return
            err = self._start_translate(gid, game, extra)
            if err:
                self.logAppended.emit(err)

    _last_prompt_title = ""

    def emit_prompt(self, title, text, buttons):
        self._last_prompt_title = title
        self.prompt.emit(title, text, json.dumps(buttons))

    @Slot(str, result=str)
    def previewCommand(self, gid):
        game = store.load_games().get(gid)
        if not game:
            return ""
        return " ".join(commands.build_command(game))

    @Slot(str, result=str)
    def openTextbox(self, gid):
        proc, msg = process.spawn_textbox(gid or None)
        if proc is not None:
            self.textbox_proc = proc
        self.logAppended.emit(msg)
        return msg

    @Slot()
    def stopGame(self):
        import signal as _sig
        if self.proc is not None:
            self.logAppended.emit("stopping…")
            self.proc.terminate()
        if self.textbox_proc is not None and self.textbox_proc.poll() is None:
            self.logAppended.emit("stopping translation readout…")
            process.kill_textbox_group(self.textbox_proc, _sig.SIGTERM)
        QTimer.singleShot(3000, self._force_stop)

    def _force_stop(self):
        import signal as _sig
        if self.proc is not None and self.proc.state() != QProcess.NotRunning:
            self.proc.kill()
        if self.proc is not None:
            gid = self._running_gid
            if gid:
                game = store.load_games().get(gid)
                if game and process.kill_strays(process.stray_token(game)):
                    self.logAppended.emit("cleaned stray processes.")
        if self.textbox_proc is not None:
            if self.textbox_proc.poll() is None:
                process.kill_textbox_group(self.textbox_proc, _sig.SIGKILL)
                self.logAppended.emit("translation readout stopped.")
            self.textbox_proc = None
        if process.kill_orphan_browsers():
            self.logAppended.emit("translator browser stopped.")

    def _read_log(self):
        if self.proc is not None:
            self.logAppended.emit(str(self.proc.readAllStandardOutput(), "utf-8", "replace").rstrip())

    def _finished(self, code, status):
        import subprocess
        self.logAppended.emit(f"\n[exited with code {code}]")
        self._set_status("Idle.")
        self._set_running(False)
        self.proc = None
        gid = self._running_gid
        self._running_gid = None
        translating, self._running_translate = self._running_translate, False
        if translating and gid:
            game = store.load_games().get(gid) or {}
            if game.get("path"):
                try:
                    r = subprocess.run(
                        [sys.executable,
                         os.path.join(paths.TRANSLATE_DIR, "harvest-hooks.py"),
                         "--exe", game["path"], "--game", gid],
                        capture_output=True, text=True, timeout=30)
                    for line in (r.stdout + r.stderr).splitlines():
                        if line.strip():
                            self.logAppended.emit(line)
                except (OSError, subprocess.SubprocessError):
                    pass
                self._model.refresh()
                self.gamesChanged.emit()

    @Slot(str, result=str)
    def pickThread(self, gid):
        game = store.load_games().get(gid)
        if not game:
            return "Unknown game."
        if not process.translate_bridge_ok():
            return "nobridge"
        self._set_status("Sampling threads… (advance the game text)")
        import threading
        threading.Thread(target=self._sample_threads, args=(gid,), daemon=True).start()
        return ""

    def _sample_threads(self, gid):
        import time as _time
        game = store.load_games().get(gid, {})
        cur = ((game.get("translate") or {}).get("thread") or "").strip()
        buckets = {}
        try:
            sys.path.insert(0, paths.TRANSLATE_DIR)
            from hook_client import parse_thread, clean_ja
            import websocket
            ws = websocket.create_connection("ws://127.0.0.1:6677", timeout=15)
            ws.settimeout(1.0)
            end = _time.time() + 20
            while _time.time() < end:
                try:
                    msg = ws.recv()
                except Exception:
                    continue
                meta, text = parse_thread(msg)
                if meta is None:
                    continue
                ja = clean_ja(text)
                if not ja:
                    continue
                key = (meta["number"], meta["name"], meta["addr"])
                b = buckets.setdefault(key, {"n": 0, "last": ""})
                b["n"] += 1
                b["last"] = ja[-120:]
            ws.close()
        except Exception as e:
            self.threadResults.emit(json.dumps({"error": str(e)}))
            self._set_status("Idle.")
            return
        out = [{"num": num, "name": name, "addr": addr, "n": b["n"],
                "last": b["last"], "current": cur in (name, str(num))}
               for (num, name, addr), b in sorted(buckets.items())]
        self.threadResults.emit(json.dumps({"threads": out}))
        self._set_status("Idle.")

    @Slot(str, str)
    def saveThread(self, gid, thread):
        games = store.load_games()
        if gid in games:
            games[gid].setdefault("translate", {})["thread"] = thread
            store.save_games(games)
            self._model.refresh()
            self.gamesChanged.emit()

    @Slot(result=str)
    def loadSettings(self):
        return json.dumps(store.load_config())

    @Slot(str)
    def saveSettings(self, cfg_json):
        try:
            cfg = json.loads(cfg_json)
        except (ValueError, TypeError):
            return
        base = store.load_config()
        base.update(cfg)
        store.save_config(base)
        self._theme.apply_override(base.get("gui.theme", "System"))


def self_test(backend, model, theme, window, warnings, qml_errors=None):
    assert model.rowCount() == len(store.load_games()), "model must mirror the library"
    assert qml_errors is not None and not qml_errors, \
        f"runtime QML errors: {qml_errors[:3]}"
    assert backend.previewCommand("__no_such_game__") == ""
    assert backend.validateGame("not json") != ""
    assert backend.validateGame(json.dumps({"name": "x", "runner": "proton", "path": "/nope"})) != ""
    assert backend.launchGame("__no_such_game__", False) != ""
    assert backend.translateGame("__no_such_game__", False) != ""
    assert backend.pickThread("__no_such_game__") != ""
    assert backend.gameDetails("__no_such_game__") == "Select a game."
    assert backend._theme.bg.startswith("#")
    backend._theme.apply_override("light")
    assert backend._theme.bg.startswith("#") and backend._theme.scheme == "light"
    backend._theme.apply_override("dark")
    assert backend._theme.scheme == "dark"
    assert isinstance(backend.listVariants(), list) and backend.listVariants()
    assert isinstance(backend.listGpus(), list) and backend.listGpus()
    assert json.loads(backend.runnersJson()).get("proton")
    assert window is not None, "Main.qml must create a root window"
    assert not warnings, f"QML warnings: {warnings[:3]}"
    print("self-test: ALL OK")


def _diagnose(app, engine, theme, model, backend):
    print("python:", sys.version.split()[0])
    try:
        from PySide6 import __version__ as pv
        from PySide6.QtCore import qVersion
        print("pyside:", pv, "qt:", qVersion())
    except Exception:
        pass
    print("app_dir:", APP_DIR)
    print("qml_dir:", os.path.join(APP_DIR, "qml"))
    print("platform:", QGuiApplication.platformName())
    print("theme source:", theme.source, "scheme:", theme.scheme, "bg:", theme.bg)
    print("games:", model.rowCount())
    print("roots:", len(engine.rootObjects()))
    ctx = engine.rootContext()
    for name in ("theme", "backend", "gamesModel"):
        obj = ctx.contextProperty(name)
        valid = False
        try:
            valid = obj is not None and obj.property("objectName") is not None
        except Exception:
            valid = obj is not None
        print(f"contextProperty {name!r}: {type(obj).__name__} valid={valid}")
    print("runtime qml errors:", len(QML_ERRORS))
    for e in QML_ERRORS[:5]:
        print("  ", e)


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Anime4K Launcher")
    qInstallMessageHandler(_capture_qt_messages)
    engine = QQmlApplicationEngine()
    qml_warnings = []
    engine.warnings.connect(lambda w: qml_warnings.extend(str(x) for x in w))
    theme = Theme(app)
    theme.apply_override(store.load_config().get("gui.theme", "System"))
    model = GamesModel(app)
    model.refresh()
    backend = GuiBackend(model, theme, app)
    app._qml_objects = (theme, model, backend)
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("gamesModel", model)
    engine.rootContext().setContextProperty("theme", theme)
    try:
        from PySide6.QtGui import QFontDatabase
        engine.rootContext().setContextProperty("fontFamilies", QFontDatabase.families())
    except Exception:
        engine.rootContext().setContextProperty("fontFamilies", [])
    engine.load(QUrl.fromLocalFile(os.path.join(APP_DIR, "qml", "Main.qml")))
    for _ in range(20):
        app.processEvents()
    diagnose = "--diagnose" in sys.argv[1:]
    if diagnose:
        _diagnose(app, engine, theme, model, backend)
    if qml_warnings or QML_ERRORS:
        logp = _log_path()
        if logp:
            try:
                with open(logp, "a", encoding="utf-8") as f:
                    f.write(f"--- {__import__('datetime').datetime.now()}\n")
                    for e in list(qml_warnings) + list(QML_ERRORS):
                        f.write(str(e) + "\n")
            except OSError:
                pass
    if "--self-test" in sys.argv[1:]:
        roots = engine.rootObjects()
        try:
            self_test(backend, model, theme, roots[0] if roots else None,
                      qml_warnings, QML_ERRORS)
        except AssertionError as e:
            print(f"self-test FAILED: {e}")
            for w in list(qml_warnings)[:5] + list(QML_ERRORS)[:5]:
                print("qml:", w)
            sys.exit(3)
        sys.exit(0)
    if diagnose:
        sys.exit(0)
    if "--screenshot" in sys.argv[1:]:
        from PySide6.QtQuick import QQuickWindow
        idx = sys.argv.index("--screenshot")
        out = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else "/tmp/anime4k-gui.png"
        roots = engine.rootObjects()
        if roots:
            win = roots[0]
            win.setWidth(1100)
            win.setHeight(700)
            for _ in range(20):
                app.processEvents()
            img = win.grabWindow()
            print("screenshot:", out, "ok=" + str(img.save(out)))
        sys.exit(0)
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
