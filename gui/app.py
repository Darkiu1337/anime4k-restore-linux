#!/usr/bin/env python3
"""anime4k-gui — Qt6 (PySide6) frontend for the Anime4K Restore launchers.

Thin UI over scripts/../scripts runners; shares ~/.config/anime4k/games.json
with the `anime4k` TUI. Default theme follows the system (qt6ct etc.);
override in Settings.
"""
import json
import os
import re
import subprocess
import sys

from PySide6.QtCore import Qt, QProcess, QProcessEnvironment, QTimer
from PySide6.QtGui import QAction, QIcon, QPalette, QColor, QPixmap
from PySide6.QtWidgets import QStyle
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QListWidget, QListWidgetItem,
    QVBoxLayout, QHBoxLayout, QPushButton, QLabel, QTextEdit, QSplitter,
    QDialog, QDialogButtonBox, QFormLayout, QComboBox, QLineEdit, QSpinBox,
    QCheckBox, QFileDialog, QMessageBox, QWizard, QWizardPage, QButtonGroup,
    QRadioButton,
)

APP_DIR = os.path.dirname(os.path.realpath(__file__))
REPO_ROOT = os.path.dirname(APP_DIR)
SCRIPTS_DIR = os.path.join(REPO_ROOT, "scripts")
SHADERS_DIR = os.path.join(REPO_ROOT, "shaders")
TRANSLATE_DIR = os.path.join(REPO_ROOT, "translate")
CONFIG_DIR = os.path.expanduser("~/.config/anime4k")
GAMES_JSON = os.path.join(CONFIG_DIR, "games.json")
CONFIG_JSON = os.path.join(CONFIG_DIR, "config.json")

# Sane clean-box fallbacks (umu-managed Proton, project shared prefix).
# Stored values are always shown as-is; these apply only when unset.
DEFAULT_PREFIX = os.path.join(os.path.expanduser("~"), ".local/share/anime4k/prefixes/default")

RUNNERS = {
    "proton": "Windows games (D3D9-12/Vulkan filtered; OpenGL runs unfiltered)",
    "rpgmaker": "RPGMaker dirs (MV/MZ filtered; other engines redirect)",
    "native": "Linux executables (Vulkan direct; OpenGL via Zink; 64-bit only)",
}

VARIANT_NOTES = {
    "L": "strongest, highest GPU cost",
    "M": "balanced",
    "S": "lightest, cheapest",
    "Soft_S": "for aliased art, light",
    "Soft_L": "for aliased art, strong",
}

DARK_PALETTE = {
    QPalette.Window: QColor(53, 53, 53),
    QPalette.WindowText: Qt.white,
    QPalette.Base: QColor(35, 35, 35),
    QPalette.AlternateBase: QColor(53, 53, 53),
    QPalette.ToolTipBase: Qt.white,
    QPalette.ToolTipText: Qt.white,
    QPalette.Text: Qt.white,
    QPalette.Button: QColor(53, 53, 53),
    QPalette.ButtonText: Qt.white,
    QPalette.BrightText: Qt.red,
    QPalette.Link: QColor(42, 130, 218),
    QPalette.Highlight: QColor(42, 130, 218),
    QPalette.HighlightedText: Qt.black,
}


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def load_games():
    data = load_json(GAMES_JSON, {})
    return data.get("games", {})


def save_games(games):
    import shutil
    if os.path.isfile(GAMES_JSON):
        try:
            shutil.copyfile(GAMES_JSON, GAMES_JSON + ".bak")
        except OSError:
            pass
    save_json(GAMES_JSON, {"games": games})


def load_config():
    return load_json(CONFIG_JSON, {})


def save_config(cfg):
    save_json(CONFIG_JSON, cfg)


def list_variants():
    """Variant names from the shader dir (auto-discovers future additions)."""
    found = []
    try:
        for fn in sorted(os.listdir(SHADERS_DIR)):
            m = re.fullmatch(r"Anime4K_Restore_(.+)\.fx", fn)
            if m:
                found.append(m.group(1))
    except OSError:
        pass
    order = ["L", "M", "S", "Soft_S", "Soft_L"]
    return [v for v in order if v in found] + [v for v in found if v not in order]


def list_gpus():
    """(display, icd-keyword) pairs; first entry is auto (= discrete GPU when detectable)."""
    names = ["auto (discrete GPU preferred)"]
    try:
        out = subprocess.run(["vulkaninfo", "--summary"], capture_output=True,
                             text=True, timeout=15).stdout
        seen = set()
        for line in out.splitlines():
            m = re.search(r"deviceName\s*=\s*(.+)", line)
            if m:
                name = m.group(1).strip()
                if name and name not in seen:
                    seen.add(name)
                    names.append(name)
    except (OSError, subprocess.SubprocessError):
        pass
    return names


def gpu_icd(name):
    if name.startswith("auto"):
        return "auto"
    if "NVIDIA" in name:
        return "nvidia"
    if any(k in name for k in ("AMD", "ATI", "Radeon")):
        return "amd"
    return "auto"


def stray_token(game):
    """pgrep token identifying this game's processes (bracketed by caller)."""
    if game.get("runner") == "rpgmaker":
        return "nw --ozone-platform"
    return os.path.basename(game.get("path", ""))


def find_strays(token):
    """PIDs matching token, self-excluding via bracket pattern. Never raises."""
    if not token:
        return []
    pat = f"[{token[0]}]{token[1:]}"
    try:
        out = subprocess.run(["pgrep", "-f", pat], capture_output=True,
                             text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    me = os.getpid()
    return [int(p) for p in out.split() if p.isdigit() and int(p) != me]


def kill_strays(token):
    """TERM, grace wait, then KILL leftovers. Returns True if anything was found."""
    import signal
    import time
    pids = find_strays(token)
    if not pids:
        return False
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    time.sleep(2)
    for pid in pids:
        try:
            os.kill(pid, 0)
        except OSError:
            continue
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass
    return True


ICON_CACHE = os.path.expanduser("~/.cache/anime4k/icons")


def _manifest_icon(game_dir):
    """icon path from an RPGMaker manifest, game-root-relative resolved."""
    for mf in (os.path.join(game_dir, "package.json"),
               os.path.join(game_dir, "www", "package.json")):
        try:
            with open(mf) as f:
                icon = json.load(f).get("window", {}).get("icon") or json.load(open(mf)).get("icon")
        except (OSError, ValueError):
            continue
        if not icon or not isinstance(icon, str):
            continue
        for cand in (os.path.join(game_dir, icon),
                     os.path.join(game_dir, "www", os.path.basename(icon))):
            if os.path.isfile(cand):
                return cand
    return None


def _exe_of(game_dir):
    """First .exe next to the game (Windows bundle shipped alongside)."""
    try:
        for fn in sorted(os.listdir(game_dir)):
            if fn.lower().endswith(".exe"):
                return os.path.join(game_dir, fn)
    except OSError:
        pass
    return None


def resolve_icon(runner, path, gid):
    """Return a usable image path for the game (cached), or None for fallback.

    Sources, in order: exe-embedded icon (icoextract) for proton titles;
    manifest art, then sibling exe, for rpgmaker/native titles; plain image
    files are copied into the cache so unplugged drives keep their icons.
    """
    os.makedirs(ICON_CACHE, exist_ok=True)
    for ext in (".png", ".ico"):
        hit = os.path.join(ICON_CACHE, gid + ext)
        if os.path.isfile(hit):
            return hit
    src = None
    if runner == "proton" and path.lower().endswith(".exe"):
        src = ("exe", path)
    elif runner in ("rpgmaker", "native"):
        base = path if os.path.isdir(path) else os.path.dirname(path)
        for cand in (_manifest_icon(base),
                    os.path.join(base, "icon.png"),
                    os.path.join(base, "icon.ico"),
                    os.path.join(base, "game", "icon.png")):
            if cand and os.path.isfile(cand):
                src = ("img", cand)
                break
        if src is None:
            exe = _exe_of(base)
            if exe:
                src = ("exe", exe)
    if src is None:
        return None
    kind, spath = src
    if kind == "img":
        dst = os.path.join(ICON_CACHE, gid + os.path.splitext(spath)[1].lower())
        try:
            import shutil
            shutil.copyfile(spath, dst)
            return dst
        except OSError:
            return spath
    # exe-embedded: extract largest icon via icoextract
    import shutil
    import subprocess
    if shutil.which("icoextract") is None:
        return None
    dst = os.path.join(ICON_CACHE, gid + ".ico")
    try:
        subprocess.run(["icoextract", spath, dst], timeout=30,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=True)
        return dst if os.path.isfile(dst) else None
    except (OSError, subprocess.SubprocessError):
        return None


def slugify(name):
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "game"


class AddWizard(QWizard):
    def __init__(self, parent=None, initial=None, lock_runner=False):
        super().__init__(parent)
        initial = initial or {}
        self._initial_translate = dict(initial.get("translate", {}))
        self.setWindowTitle("Edit game" if lock_runner else "Add game")
        self.setOption(QWizard.NoBackButtonOnStartPage, True)

        self.runner_group = QButtonGroup(self)
        self.runner_buttons = {}
        p1 = QWizardPage()
        p1.setTitle("Runner")
        p1.setSubTitle("Limits are shown so you know what to expect." +
                       (" (locked: runner changes mean re-adding)" if lock_runner else ""))
        lay1 = QVBoxLayout()
        for i, (key, desc) in enumerate(RUNNERS.items()):
            rb = QRadioButton(f"{key} — {desc}")
            if i == 0:
                rb.setChecked(True)
            self.runner_group.addButton(rb, i)
            self.runner_buttons[key] = rb
            lay1.addWidget(rb)
        if initial.get("runner") in self.runner_buttons:
            self.runner_buttons[initial["runner"]].setChecked(True)
        if lock_runner:
            for rb in self.runner_buttons.values():
                rb.setEnabled(False)
        p1.setLayout(lay1)
        self.addPage(p1)

        p2 = QWizardPage()
        p2.setTitle("Game location")
        lay2 = QFormLayout()
        self.path_edit = QLineEdit(initial.get("path", ""))
        browse = QPushButton("Browse…")
        browse.clicked.connect(self._browse)
        detect_btn = QPushButton("Detect")
        detect_btn.setToolTip("Identify the engine from the path and pre-select the runner")
        detect_btn.clicked.connect(self._detect)
        row = QHBoxLayout()
        row.addWidget(self.path_edit)
        row.addWidget(browse)
        row.addWidget(detect_btn)
        lay2.addRow("Path:", row)
        self.detect_label = QLabel("Tip: Detect fills in the runner from the previous page.")
        self.detect_label.setWordWrap(True)
        lay2.addRow("", self.detect_label)
        p2.setLayout(lay2)
        self.addPage(p2)

        p3 = QWizardPage()
        p3.setTitle("Filter and performance")
        lay3 = QFormLayout()
        self.variant_combo = QComboBox()
        for v in list_variants() or ["L"]:
            note = VARIANT_NOTES.get(v, "")
            self.variant_combo.addItem(f"{v} — {note}" if note else v, v)
        idx = self.variant_combo.findData(initial.get("variant", "L"))
        self.variant_combo.setCurrentIndex(max(0, idx))
        lay3.addRow("Variant:", self.variant_combo)
        self.gpu_combo = QComboBox()
        self.gpu_combo.addItems(list_gpus())
        gidx = 0
        if initial.get("gpu"):
            gidx = max(0, self.gpu_combo.findText(initial["gpu"]))
        self.gpu_combo.setCurrentIndex(gidx)
        lay3.addRow("Game GPU:", self.gpu_combo)
        self.fps_spin = QSpinBox()
        self.fps_spin.setRange(0, 480)
        self.fps_spin.setValue(int(initial.get("fps", 60) or 60))
        self.fps_spin.setSpecialValueText("off")
        lay3.addRow("FPS cap (0 = off):", self.fps_spin)
        self.hud_check = QCheckBox("Show fps overlay while playing")
        self.hud_check.setChecked(initial.get("hud") == "1")
        lay3.addRow("", self.hud_check)
        self.lang_combo = QComboBox()
        self.lang_combo.setEditable(True)
        self.lang_combo.addItem("System default")
        for loc in ("ja_JP.UTF-8", "zh_CN.UTF-8", "zh_TW.UTF-8", "ko_KR.UTF-8",
                    "fr_FR.UTF-8", "de_DE.UTF-8", "es_ES.UTF-8", "pt_BR.UTF-8",
                    "ru_RU.UTF-8"):
            self.lang_combo.addItem(loc)
        if initial.get("lang"):
            idx = self.lang_combo.findText(initial["lang"])
            if idx >= 0:
                self.lang_combo.setCurrentIndex(idx)
            else:
                self.lang_combo.setCurrentText(initial["lang"])
        lay3.addRow("Language (Proton/native):", self.lang_combo)
        self.prefix_check = QCheckBox("Separate Wine prefix for this game (Proton only)")
        self.prefix_check.setChecked(initial.get("prefix_mode", "shared") == "game")
        lay3.addRow("", self.prefix_check)
        p3.setLayout(lay3)
        self.addPage(p3)

        p4 = QWizardPage()
        p4.setTitle("Name")
        lay4 = QFormLayout()
        self.name_edit = QLineEdit(initial.get("name", ""))
        lay4.addRow("Display name:", self.name_edit)
        p4.setLayout(lay4)
        self.addPage(p4)

        p5 = QWizardPage()
        p5.setTitle("Translation (Japanese VNs)")
        lay5 = QFormLayout()
        tr_init = initial.get("translate", {})
        self.tr_enable = QCheckBox("Translate Japanese dialogue via DeepL")
        self.tr_enable.setChecked(tr_init.get("enabled") == "1")
        lay5.addRow("", self.tr_enable)
        self.tr_hook = QLineEdit(tr_init.get("hook_code", ""))
        self.tr_hook.setPlaceholderText("hook code, e.g. HSX10@54DC0:game.exe (optional)")
        lay5.addRow("Hook code:", self.tr_hook)
        note = QLabel("Proton/Windows games only. Filter and translation compose in one "
                      "launch. First run: enable, launch with Translate, pick the story thread "
                      "in Textractor (Setup shows its window), paste its code here.")
        note.setWordWrap(True)
        lay5.addRow("", note)
        p5.setLayout(lay5)
        self.addPage(p5)

    def _browse(self):
        from PySide6.QtCore import QDir, QUrl
        runner = self.runner()
        dlg = QFileDialog(self)
        dlg.setOption(QFileDialog.DontResolveSymlinks, False)
        # Pin well-known places so removable mounts are one click away even
        # when the portal dialog hides them from its default sidebar.
        # Each *mounted drive* gets its own entry (not the bare profile dir).
        sidebar = [QUrl.fromLocalFile(os.path.expanduser("~")),
                   QUrl.fromLocalFile("/")]
        media = f"/run/media/{os.environ.get('USER', '')}"
        try:
            mounts = sorted(d for d in os.listdir(media)
                            if os.path.isdir(os.path.join(media, d)))
        except OSError:
            mounts = []
        for m in mounts:
            sidebar.append(QUrl.fromLocalFile(os.path.join(media, m)))
        dlg.setSidebarUrls(sidebar)
        last = load_config().get("gui.last_dir", os.path.expanduser("~"))
        if os.path.isdir(last):
            dlg.setDirectory(last)
        if runner == "rpgmaker":
            dlg.setWindowTitle("Select RPGMaker game folder")
            dlg.setFileMode(QFileDialog.Directory)
            dlg.setOption(QFileDialog.ShowDirsOnly, True)
        else:
            if runner == "proton":
                dlg.setWindowTitle("Select Windows game executable")
                dlg.setNameFilters(["Windows executables (*.exe *.EXE)", "All files (*)"])
            else:
                dlg.setWindowTitle("Select game executable")
            dlg.setFileMode(QFileDialog.ExistingFile)
        if dlg.exec() == QDialog.Accepted and dlg.selectedFiles():
            path = dlg.selectedFiles()[0]
            self.path_edit.setText(path)
            cfg = load_config()
            cfg["gui.last_dir"] = path if os.path.isdir(path) else os.path.dirname(path)
            save_config(cfg)

    def runner(self):
        for key, rb in self.runner_buttons.items():
            if rb.isChecked():
                return key
        return "proton"

    def _detect(self):
        path = self.path_edit.text().strip()
        if not path or not os.path.exists(path):
            self.detect_label.setText("Set a valid path first (Browse… or paste).")
            return
        lib = os.path.join(REPO_ROOT, "scripts", "anime4k-lib.sh")
        try:
            out = subprocess.run(
                ["bash", "-c", f'source "{lib}" && ak_detect_engine "$0"', path],
                capture_output=True, text=True, timeout=30).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            self.detect_label.setText("Detection failed to run.")
            return
        parts = out.split("|", 4)
        if len(parts) != 5:
            self.detect_label.setText("Detection returned garbage.")
            return
        engine, runner, conf, root, detail = parts
        if runner in self.runner_buttons and conf in ("high", "medium"):
            self.runner_buttons[runner].setChecked(True)
            # Runners consume different path kinds: rpgmaker needs the folder.
            if runner == "rpgmaker" and not os.path.isdir(self.path_edit.text().strip()) \
                    and os.path.isdir(root):
                self.path_edit.setText(root)
                self.detect_label.setText(
                    f"Detected: {detail} → runner '{runner}' ({conf}). "
                    f"Path set to game folder.")
            else:
                self.detect_label.setText(f"Detected: {detail} → runner '{runner}' ({conf} confidence).")
        else:
            self.detect_label.setText(
                f"Detected: {detail} (confidence: {conf}) — pick the runner manually.")

    def result_data(self):
        path = self.path_edit.text().strip()
        name = self.name_edit.text().strip() or os.path.basename(path.rstrip("/"))
        lang = self.lang_combo.currentText().strip()
        if lang == "System default":
            lang = ""
        tr_prev = (self._initial_translate if hasattr(self, "_initial_translate") else {})
        return {
            "name": name,
            "runner": self.runner(),
            "path": path,
            "variant": self.variant_combo.currentData(),
            "gpu": self.gpu_combo.currentText(),
            "fps": "off" if self.fps_spin.value() == 0 else str(self.fps_spin.value()),
            "hud": "1" if self.hud_check.isChecked() else "0",
            "lang": lang,
            "prefix_mode": "game" if self.prefix_check.isChecked() else "shared",
            "translate": {
                "enabled": "1" if (self.tr_enable.isChecked()
                                   and self.runner() == "proton") else "0",
                "hook_code": self.tr_hook.text().strip(),
                "hook_mode": tr_prev.get("hook_mode", "unknown"),
                "thread": tr_prev.get("thread", ""),
            },
        }


class SettingsDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Settings")
        cfg = load_config()
        lay = QFormLayout(self)
        self.prefix_edit = QLineEdit(cfg.get("prefix", DEFAULT_PREFIX))
        self.prefix_edit.setPlaceholderText(DEFAULT_PREFIX + " (project shared prefix)")
        lay.addRow("Wine prefix default:", self.prefix_edit)
        self.proton_edit = QLineEdit(cfg.get("proton", ""))
        self.proton_edit.setPlaceholderText("(umu-managed UMU-Proton — leave empty, or a name from compatibilitytools.d)")
        lay.addRow("Proton default:", self.proton_edit)
        self.layer_edit = QLineEdit(cfg.get("layer_dir", ""))
        self.layer_edit.setPlaceholderText("empty = system layer")
        lay.addRow("vkBasalt layer dir (empty = system):", self.layer_edit)
        self.theme_combo = QComboBox()
        self.theme_combo.addItem("System (follows qt6ct / desktop)")
        for style in ("Breeze-Dark", "Fusion-Dark", "Fusion-Light"):
            self.theme_combo.addItem(style)
        cur = cfg.get("gui.theme", "System")
        idx = self.theme_combo.findText(cur, Qt.MatchStartsWith)
        self.theme_combo.setCurrentIndex(max(0, idx))
        lay.addRow("Theme:", self.theme_combo)
        buttons = QDialogButtonBox(QDialogButtonBox.Save | QDialogButtonBox.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        lay.addRow(buttons)

    def result_config(self, base):
        base = dict(base)
        base["prefix"] = self.prefix_edit.text().strip()
        base["proton"] = self.proton_edit.text().strip()
        base["layer_dir"] = self.layer_edit.text().strip()
        base["gui.theme"] = self.theme_combo.currentText()
        return base


def apply_theme(app, name):
    from PySide6.QtWidgets import QStyleFactory
    if name.startswith("System"):
        app.setStyleSheet("")
        return
    style_name = name.split("-")[0]
    if style_name in QStyleFactory.keys():
        app.setStyle(QStyleFactory.create(style_name))
    if name.endswith("Dark"):
        pal = QPalette()
        for role, color in DARK_PALETTE.items():
            pal.setColor(role, color)
        app.setPalette(pal)
    else:
        app.setPalette(app.style().standardPalette())


def build_command(game):
    """Return argv list for a library entry (mirrors the bash runners)."""
    runner = game["runner"]
    variant = game.get("variant", "L")
    fps = game.get("fps", "60")
    hud = game.get("hud", "0")
    gpu = game.get("gpu", "auto (discrete GPU preferred)")
    pmode = game.get("prefix_mode", "shared")
    lang = game.get("lang", "")
    path = game["path"]
    if runner == "proton":
        argv = [os.path.join(SCRIPTS_DIR, "proton-anime4k.sh"),
                "--variant", variant, "--fps", fps,
                "--prefix-mode", pmode if pmode in ("shared", "game") else "shared"]
        if hud == "1":
            argv.append("--hud")
        if lang:
            argv += ["--lang", lang]
        if not gpu.startswith("auto"):
            argv += ["--dxvk-device", gpu]
        argv.append(path)
    elif runner == "rpgmaker":
        argv = [os.path.join(SCRIPTS_DIR, "rpgmaker-anime4k.sh"),
                "--variant", variant, "--gpu", gpu_icd(gpu),
                "--fps", fps]
        if hud == "1":
            argv.append("--hud")
        argv += ["--gamepath", path]
    else:
        argv = [os.path.join(SCRIPTS_DIR, "native-anime4k.sh"),
                "--variant", variant, "--gpu", gpu_icd(gpu),
                "--fps", fps]
        if hud == "1":
            argv.append("--hud")
        if lang:
            argv += ["--lang", lang]
        argv.append(path)
    return argv


def build_translate_command(game, gid, setup=False):
    """Argv for a translation session (filter + DeepL in one launch).
    setup=True shows the Textractor window for first-time thread picking;
    the recorded hook auto-inserts either way (seeded SavedHooks)."""
    argv = [os.path.join(TRANSLATE_DIR, "vn-launch.sh"),
            "--exe", game["path"], "--gameid", gid,
            "--filter", game.get("variant", "L")]
    if game.get("lang"):
        argv += ["--lang", game["lang"]]
    hook = (game.get("translate") or {}).get("hook_code", "").strip()
    if hook:
        argv += ["--hook-code", hook]
    if setup:
        argv += ["--setup"]
    return argv


def translate_bridge_ok():
    """True when something answers :6677 with a real ws handshake.
    Never probe with bare TCP: the stock bridge panics on non-handshakes."""
    try:
        import websocket
        ws = websocket.create_connection("ws://127.0.0.1:6677", timeout=3)
        ws.close()
        return True
    except Exception:
        return False


TEXTBOX_PROG = "textbox.py"


def _textbox_pattern():
    return r"[t]extbox\.py --start-workers"


def textbox_pids():
    """PIDs of a running textbox backend (workers = owns the translator)."""
    try:
        out = subprocess.run(["pgrep", "-f", _textbox_pattern()],
                             capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return [p for p in (x.strip() for x in out.splitlines()) if p]


def _translate_cdp_profile():
    """(full path, basename) of the isolated translator-browser profile.
    Never the real browser profile — automation always gets its own dir."""
    try:
        with open(os.path.join(TRANSLATE_DIR, "config.json"), encoding="utf-8") as f:
            prof = (json.load(f) or {}).get("brave_profile", "")
    except (OSError, ValueError):
        prof = ""
    prof = os.path.expanduser(os.path.expandvars(
        prof or "~/.cache/vn-translate/brave-cdp-profile"))
    base = os.path.basename(prof.rstrip("/")) or "brave-cdp-profile"
    return prof, base


def _textbox_brave_pattern():
    """pkill -f pattern matching ONLY translator browsers: the isolated
    profile marker in the cmdline, whatever the binary (brave/chromium/
    chrome/edge/...). A normal browser never carries this path."""
    _, base = _translate_cdp_profile()
    esc = "".join(("\\" + ch) if ch in ".+*?()[]{}^$|\\" else ch for ch in base)
    if esc and esc[0].isalnum():
        return f"user-data-dir=[^ ]*[{esc[0]}]{esc[1:]}"
    return f"user-data-dir=[^ ]*{esc}"


def _kill_textbox_group(proc, sig):
    """Signal the textbox process group (backend + translator browser it
    spawned). Returns True if a live group was signaled."""
    try:
        if proc is None or proc.poll() is not None:
            return False
        os.killpg(os.getpgid(proc.pid), sig)
        return True
    except (OSError, ProcessLookupError):
        return False


def translate_wedge_pids(game_base=""):
    """PIDs of wedged translate containers: umu-run ... hook .vbs older than
    ~3 min while no game/hooker process lives and the bridge is down.
    That's the wineserver -w stall signature (container alive, exes dead)."""
    import time
    try:
        out = subprocess.run(["ps", "-eo", "pid,etimes,args"], capture_output=True,
                             text=True, timeout=10).stdout.splitlines()
    except (OSError, subprocess.SubprocessError):
        return []
    game_alive = False
    old_launchers = []
    gb = os.path.basename(game_base or "").lower()
    for line in out:
        parts = line.split(None, 2)
        if len(parts) != 3:
            continue
        pid, etime, args = parts
        if not pid.isdigit():
            continue
        if ("umu-run" in args and "hook" in args and ".vbs" in args
                and "ps -eo" not in args):
            try:
                if int(etime) > 180:
                    old_launchers.append(int(pid))
            except ValueError:
                pass
        low = args.lower()
        if (("textractor.exe" in low or (gb and gb in low))
                and "umu-run" not in low and "ps -eo" not in args):
            game_alive = True
    if old_launchers and not game_alive and not translate_bridge_ok():
        return old_launchers
    return []


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Anime4K Launcher")
        self.resize(1000, 650)
        self.proc = None
        self._running_gid = None
        self.textbox_proc = None

        menu = self.menuBar().addMenu("File")
        act_settings = QAction("Settings…", self)
        act_settings.triggered.connect(self.open_settings)
        menu.addAction(act_settings)
        act_quit = QAction("Quit", self)
        act_quit.triggered.connect(self.close)
        menu.addAction(act_quit)

        central = QWidget()
        self.setCentralWidget(central)
        main = QHBoxLayout(central)
        splitter = QSplitter()
        main.addWidget(splitter)

        left = QWidget()
        ll = QVBoxLayout(left)
        ll.addWidget(QLabel("Games"))
        self.game_list = QListWidget()
        self.game_list.itemSelectionChanged.connect(self.show_details)
        ll.addWidget(self.game_list)
        row = QHBoxLayout()
        add_btn = QPushButton("Add…")
        add_btn.clicked.connect(self.add_game)
        edit_btn = QPushButton("Edit…")
        edit_btn.clicked.connect(self.edit_game)
        remove_btn = QPushButton("Remove")
        remove_btn.clicked.connect(self.remove_game)
        row.addWidget(add_btn)
        row.addWidget(edit_btn)
        row.addWidget(remove_btn)
        ll.addLayout(row)
        splitter.addWidget(left)

        right = QWidget()
        rl = QVBoxLayout(right)
        headrow = QHBoxLayout()
        self.detail_icon = QLabel()
        self.detail_icon.setFixedSize(64, 64)
        self.detail_icon.setScaledContents(True)
        headrow.addWidget(self.detail_icon)
        self.detail_label = QLabel("Select a game.")
        self.detail_label.setWordWrap(True)
        headrow.addWidget(self.detail_label, 1)
        rl.addLayout(headrow)
        btnrow = QHBoxLayout()
        self.launch_btn = QPushButton("Launch")
        self.launch_btn.clicked.connect(lambda: self.launch_selected(False))
        self.ab_btn = QPushButton("Launch unfiltered (A/B)")
        self.ab_btn.clicked.connect(lambda: self.launch_selected(True))
        self.tr_btn = QPushButton("Translate")
        self.tr_btn.setToolTip("Launch filtered + DeepL translation (Proton games with translate enabled)")
        self.tr_btn.clicked.connect(lambda: self.launch_translate(False))
        self.tr_setup_btn = QPushButton("Setup…")
        self.tr_setup_btn.setToolTip("Launch with the Textractor window visible to pick the story thread (first run per game)")
        self.tr_setup_btn.clicked.connect(lambda: self.launch_translate(True))
        self.tr_pick_btn = QPushButton("Pick thread…")
        self.tr_pick_btn.setToolTip("Sample live threads from the bridge and choose which one feeds translation (no Textractor clicking)")
        self.tr_pick_btn.clicked.connect(self.pick_thread)
        self.textbox_btn = QPushButton("Textbox")
        self.textbox_btn.setToolTip("Open the translation readout window")
        self.textbox_btn.clicked.connect(lambda: self.open_textbox())
        self.stop_btn = QPushButton("Stop")
        self.stop_btn.setEnabled(False)
        self.stop_btn.clicked.connect(self.stop_game)
        self.dry_btn = QPushButton("Preview command")
        self.dry_btn.clicked.connect(self.preview_command)
        btnrow.addWidget(self.launch_btn)
        btnrow.addWidget(self.ab_btn)
        btnrow.addWidget(self.tr_btn)
        btnrow.addWidget(self.tr_setup_btn)
        btnrow.addWidget(self.tr_pick_btn)
        btnrow.addWidget(self.textbox_btn)
        btnrow.addWidget(self.stop_btn)
        btnrow.addWidget(self.dry_btn)
        rl.addLayout(btnrow)
        self.status_label = QLabel("Idle.")
        rl.addWidget(self.status_label)
        self.tr_status = QLabel("")
        self.tr_status.setToolTip("Translation bridge (Textractor :6677) status")
        rl.addWidget(self.tr_status)
        self.tr_timer = QTimer(self)
        self.tr_timer.timeout.connect(self.poll_translate_status)
        self.tr_timer.start(3000)
        self.log_view = QTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setPlaceholderText("Launch output appears here…")
        rl.addWidget(self.log_view, 1)
        splitter.addWidget(right)
        splitter.setSizes([300, 700])

        self.refresh_list()

    def refresh_list(self):
        games = load_games()
        cur = self.selected_id()
        fallback = QApplication.style().standardIcon(QStyle.SP_MediaPlay)
        self.game_list.clear()
        for gid, g in sorted(games.items(), key=lambda kv: kv[1].get("name", "")):
            item = QListWidgetItem(f"{g.get('name', gid)}  ({g.get('runner', '?')}, {g.get('variant', '?')})")
            item.setData(Qt.UserRole, gid)
            icon_path = resolve_icon(g.get("runner", ""), g.get("path", ""), gid)
            item.setIcon(QIcon(icon_path) if icon_path else fallback)
            self.game_list.addItem(item)
            if gid == cur:
                item.setSelected(True)

    def selected_id(self):
        items = self.game_list.selectedItems()
        return items[0].data(Qt.UserRole) if items else None

    def show_details(self):
        gid = self.selected_id()
        if not gid:
            self.detail_label.setText("Select a game.")
            self.detail_icon.setPixmap(QPixmap())
            return
        g = load_games().get(gid, {})
        tr = g.get("translate", {})
        tr_txt = ""
        if tr.get("enabled") == "1":
            tr_txt = (f"Translation: on ({tr.get('hook_code') or 'hook auto-detect'})"
                      + (f", thread {tr.get('thread')}" if tr.get("thread") else "")
                      + "<br>")
        self.detail_label.setText(
            f"<b>{g.get('name', gid)}</b><br>"
            f"Runner: {g.get('runner', '?')} &nbsp; Variant: {g.get('variant', '?')}<br>"
            f"GPU: {g.get('gpu', '?')} &nbsp; FPS cap: {g.get('fps', '?')} &nbsp; "
            f"Overlay: {'on' if g.get('hud') == '1' else 'off'}<br>"
            + (f"Prefix: {g.get('prefix_mode', 'shared')}<br>" if g.get("runner") == "proton" else "")
            + (f"Language: {g.get('lang')}<br>" if g.get("lang") else "")
            + tr_txt
            + f"Path: {g.get('path', '?')}")
        icon_path = resolve_icon(g.get("runner", ""), g.get("path", ""), gid)
        if icon_path:
            icon = QIcon(icon_path)
        else:
            icon = QApplication.style().standardIcon(QStyle.SP_MediaPlay)
        self.detail_icon.setPixmap(icon.pixmap(64, 64))
        # Logs belong to the selected game: never show another game's output.
        self.log_view.clear()
        self.log_view.append(f"— {g.get('name', gid)}: launch to populate logs —\n")

    def add_game(self):
        wiz = AddWizard(self)
        if wiz.exec() != QDialog.Accepted:
            return
        data = wiz.result_data()
        if not data["path"] or not os.path.exists(data["path"]):
            QMessageBox.warning(self, "Add game", "That path does not exist.")
            return
        if data["runner"] == "rpgmaker" and not os.path.isdir(data["path"]):
            QMessageBox.warning(self, "Add game",
                                "The rpgmaker runner needs the game folder, not a file.\n"
                                "Use Detect (or pick the folder containing www/).")
            return
        games = load_games()
        gid = slugify(data["name"])
        base, n = gid, 2
        while gid in games:
            gid = f"{base}-{n}"
            n += 1
        games[gid] = data
        save_games(games)
        self.refresh_list()

    def edit_game(self):
        gid = self.selected_id()
        if not gid:
            return
        games = load_games()
        game = games.get(gid)
        if not game:
            return
        wiz = AddWizard(self, initial=game, lock_runner=True)
        if wiz.exec() != QDialog.Accepted:
            return
        data = wiz.result_data()
        if not data["path"] or not os.path.exists(data["path"]):
            QMessageBox.warning(self, "Edit game", "That path does not exist.")
            return
        data["runner"] = game.get("runner", data["runner"])
        if data["runner"] == "rpgmaker" and not os.path.isdir(data["path"]):
            QMessageBox.warning(self, "Edit game",
                                "The rpgmaker runner needs the game folder, not a file.")
            return
        games[gid] = data
        save_games(games)
        self.refresh_list()
        for i in range(self.game_list.count()):
            if self.game_list.item(i).data(Qt.UserRole) == gid:
                self.game_list.setCurrentRow(i)
                break

    def remove_game(self):
        gid = self.selected_id()
        if not gid:
            return
        g = load_games().get(gid, {})
        if QMessageBox.question(self, "Remove game",
                                f"Remove '{g.get('name', gid)}' from the library?") != QMessageBox.Yes:
            return
        games = load_games()
        games.pop(gid, None)
        save_games(games)
        self.refresh_list()

    def launch_selected(self, unfiltered):
        gid = self.selected_id()
        if not gid:
            return
        game = load_games().get(gid)
        if not game:
            return
        if not os.path.exists(game["path"]):
            QMessageBox.warning(self, "Launch", f"Path no longer exists:\n{game['path']}")
            return
        if self.proc is not None:
            QMessageBox.information(self, "Launch", "A game is already running.")
            return
        token = stray_token(game)
        if find_strays(token):
            # A previous run survived (common: wrapper dies, game lives on).
            # Single-instance runtimes would hand this launch to that stale
            # process — with ITS filter state, not ours.
            mode_txt = "unfiltered" if unfiltered else "filtered"
            box = QMessageBox(self)
            box.setWindowTitle("Stale game processes")
            box.setText(f"Leftover processes of '{game.get('name', gid)}' are still "
                        f"running.\nLaunching {mode_txt} now would attach to them "
                        f"instead of starting fresh.")
            kill_btn = box.addButton("Kill && Launch", QMessageBox.AcceptRole)
            anyway_btn = box.addButton("Launch anyway", QMessageBox.DestructiveRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            clicked = box.clickedButton()
            if clicked == kill_btn:
                self.log_view.append("cleaned stray processes.")
                kill_strays(token)
            elif clicked != anyway_btn:
                return
        argv = build_command(game)
        env = QProcessEnvironment.systemEnvironment()
        if unfiltered:
            # Structural off, two halves (both required):
            # 1. scrub any inherited layer variables, and
            # 2. tell the child script to stand down via DISABLE_VKBASALT=1
            #    (the script would otherwise re-arm the whole layer itself
            #    from config — scrubbing alone only cleans our own doorstep).
            for var in ("VK_ADD_LAYER_PATH", "VK_INSTANCE_LAYERS",
                        "ENABLE_VKBASALT", "VKBASALT_CONFIG_FILE"):
                env.remove(var)
            env.insert("DISABLE_VKBASALT", "1")
        import datetime
        stamp = datetime.datetime.now().strftime("%H:%M:%S")
        mode = "unfiltered A/B" if unfiltered else f"filtered ({game.get('variant', '')})"
        self.log_view.clear()
        self.log_view.append(f"[{stamp}] {game.get('name', gid)} — {mode}")
        self.log_view.append(f"$ {' '.join(argv)}\n")
        self.proc = QProcess(self)
        self.proc.setProgram(argv[0])
        self.proc.setArguments(argv[1:])
        self.proc.setProcessEnvironment(env)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self._read_log)
        self.proc.finished.connect(self._finished)
        self.proc.start()
        if not self.proc.waitForStarted(10000):
            QMessageBox.warning(self, "Launch", "Failed to start the launcher script.")
            self.proc = None
            return
        self.status_label.setText(f"Running {game.get('name', '')} — {mode}…")
        self.stop_btn.setEnabled(True)
        self._running_gid = gid

    def launch_translate(self, setup=False):
        import datetime
        gid = self.selected_id()
        if not gid:
            return
        game = load_games().get(gid)
        if not game:
            return
        if game.get("runner") != "proton":
            QMessageBox.warning(self, "Translate",
                                "Translation needs a Proton/Windows game.")
            return
        if game.get("translate", {}).get("enabled") != "1":
            QMessageBox.warning(self, "Translate",
                                "Enable translation for this game first (Edit…).")
            return
        if not setup and not (game.get("translate", {}).get("hook_code") or "").strip():
            # No recorded hook yet: Textractor would come up hidden with
            # nothing to insert. Redirect to a visible setup launch instead.
            box = QMessageBox(self)
            box.setWindowTitle("No hook recorded")
            box.setText("No hook code is recorded for this game yet.\n"
                        "Launch Setup (Textractor visible) to pick the story thread?")
            setup_btn = box.addButton("Launch Setup…", QMessageBox.AcceptRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            if box.clickedButton() != setup_btn:
                return
            setup = True
        if not os.path.exists(game["path"]):
            QMessageBox.warning(self, "Translate", f"Path no longer exists:\n{game['path']}")
            return
        if self.proc is not None:
            QMessageBox.information(self, "Translate", "A game is already running.")
            return
        if translate_bridge_ok():
            # A session is live: offer to replace it (stop fully, then launch
            # fresh) or just open the Textbox onto it. Never silently stack.
            box = QMessageBox(self)
            box.setWindowTitle("Translation session live")
            box.setText("A translation session is already running.\n"
                        "Replace it with a fresh launch, or open the Textbox?")
            replace_btn = box.addButton("Stop && Launch new", QMessageBox.AcceptRole)
            textbox_btn = box.addButton("Open Textbox", QMessageBox.ActionRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            clicked = box.clickedButton()
            if clicked == textbox_btn:
                self.open_textbox()
                return
            if clicked != replace_btn:
                return
            self.log_view.append("stopping live session for relaunch…")
            self.status_label.setText("Stopping live session…")
            QApplication.processEvents()
            try:
                subprocess.run([os.path.join(TRANSLATE_DIR, "vn-launch.sh"),
                                "--stop-exe", game["path"]], timeout=90,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except (OSError, subprocess.SubprocessError):
                pass
            self.log_view.append("stopped.")
        wedge = translate_wedge_pids(game.get("path", ""))
        if wedge:
            # Wedged earlier container (exes dead, wineserver held): every new
            # launch would park behind `wineserver -w` forever.
            box = QMessageBox(self)
            box.setWindowTitle("Wedged translation session")
            box.setText("A previous translation container is stuck (no game running, "
                        "prefix held).\nNew launches stall behind it until cleared.")
            kill_btn = box.addButton("Clear && Launch", QMessageBox.AcceptRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            if box.clickedButton() != kill_btn:
                return
            self.log_view.append("clearing wedged session…")
            self.status_label.setText("Clearing wedged session…")
            QApplication.processEvents()
            try:
                subprocess.run([os.path.join(TRANSLATE_DIR, "vn-launch.sh"),
                                "--stop-exe", game["path"]], timeout=90,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except (OSError, subprocess.SubprocessError):
                pass
            self.log_view.append("cleared.")
        token = stray_token(game)
        if find_strays(token):
            # Same trap as filter launches: a wedged earlier session (container
            # alive, exes dead) parks every new launch behind `wineserver -w`.
            box = QMessageBox(self)
            box.setWindowTitle("Stale game processes")
            box.setText(f"Leftover processes of '{game.get('name', gid)}' are still "
                        f"running.\nA translation launch would stall behind them.")
            kill_btn = box.addButton("Kill && Launch", QMessageBox.AcceptRole)
            anyway_btn = box.addButton("Launch anyway", QMessageBox.DestructiveRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            clicked = box.clickedButton()
            if clicked == kill_btn:
                self.log_view.append("cleaned stray processes.")
                kill_strays(token)
            elif clicked != anyway_btn:
                return
        argv = build_translate_command(game, gid, setup)
        env = QProcessEnvironment.systemEnvironment()
        stamp = datetime.datetime.now().strftime("%H:%M:%S")
        self.log_view.clear()
        mode = "setup (pick the story thread in Textractor)" if setup else "filtered + translation"
        self.log_view.append(f"[{stamp}] {game.get('name', gid)} — {mode}")
        self.log_view.append(f"$ {' '.join(argv)}\n")
        self.proc = QProcess(self)
        self.proc.setProgram(argv[0])
        self.proc.setArguments(argv[1:])
        self.proc.setProcessEnvironment(env)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self._read_log)
        self.proc.finished.connect(self._finished)
        self.proc.start()
        if not self.proc.waitForStarted(10000):
            QMessageBox.warning(self, "Translate", "Failed to start the translation launcher.")
            self.proc = None
            return
        self.status_label.setText(f"Running {game.get('name', '')} — {mode}…")
        self.stop_btn.setEnabled(True)
        self._running_gid = gid
        self._running_translate = True
        self._setup_session = setup
        # The readout belongs to the session: play gets game + textbox +
        # browser in one click; setup additionally shows Textractor, and the
        # textbox (following selection until a thread is recorded) verifies
        # translation live while picking. Refuses if one already runs.
        self.open_textbox()

    def pick_thread(self):
        """Sample live vn-bridge v2 threads and store the chosen one as
        games.json translate.thread (name). No Textractor clicking needed."""
        import time as _time
        gid = self.selected_id()
        if not gid:
            return
        games = load_games()
        game = games.get(gid)
        if not game:
            return
        if not translate_bridge_ok():
            box = QMessageBox(self)
            box.setWindowTitle("Bridge down")
            box.setText("No live translation session (bridge :6677 silent).\n"
                        "Launch Setup first so threads start flowing?")
            setup_btn = box.addButton("Launch Setup…", QMessageBox.AcceptRole)
            box.addButton(QMessageBox.Cancel)
            box.exec()
            if box.clickedButton() == setup_btn:
                self.launch_translate(True)
            return
        try:
            sys.path.insert(0, TRANSLATE_DIR)
            from hook_client import parse_thread, clean_ja
            import websocket
        except Exception as e:
            QMessageBox.warning(self, "Pick thread", f"Picker unavailable: {e}")
            return
        self.status_label.setText("Sampling threads… (advance the game text)")
        QApplication.processEvents()
        buckets = {}
        try:
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
            QMessageBox.warning(self, "Pick thread", f"Sampling failed: {e}")
            self.status_label.setText("Idle.")
            return
        if not buckets:
            QMessageBox.information(
                self, "Pick thread",
                "No tagged threads seen in 15s.\nAdvance the in-game text and retry.\n"
                "(Needs the v2 bridge: relaunch after updating Textractor.)")
            self.status_label.setText("Idle.")
            return
        from PySide6.QtWidgets import QDialog, QVBoxLayout, QListWidget, QDialogButtonBox
        dlg = QDialog(self)
        dlg.setWindowTitle(f"Pick thread — {game.get('name', gid)}")
        lay = QVBoxLayout(dlg)
        lst = QListWidget(dlg)
        cur_thread = ((game.get("translate") or {}).get("thread") or "").strip()
        for (num, name, addr), b in sorted(buckets.items()):
            mark = "  ← current" if cur_thread in (name, str(num)) else ""
            item = QListWidgetItem(f"{name}  (#{num}, {b['n']} lines){mark}\n{b['last']}")
            item.setData(Qt.UserRole, name)
            lst.addItem(item)
        follow = QListWidgetItem("Follow Textractor's own selection (*)")
        follow.setData(Qt.UserRole, "")
        lst.addItem(follow)
        lay.addWidget(lst)
        btns = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        btns.accepted.connect(dlg.accept)
        btns.rejected.connect(dlg.reject)
        lay.addWidget(btns)
        self.status_label.setText("Idle.")
        if dlg.exec() != QDialog.Accepted or not lst.currentItem():
            return
        thread = lst.currentItem().data(Qt.UserRole)
        games[gid].setdefault("translate", {})["thread"] = thread
        save_games(games)
        self.show_details()
        QMessageBox.information(self, "Pick thread",
                                f"Thread saved: {thread or 'follow Textractor (*)'}.\n"
                                f"Open the Textbox to read from it.")

    def open_textbox(self):
        import subprocess as _sp
        argv = [os.path.join(TRANSLATE_DIR, TEXTBOX_PROG), "--start-workers"]
        try:
            game = load_games().get(self.selected_id() or "")
            thread = ((game or {}).get("translate") or {}).get("thread", "").strip()
            if thread:
                argv += ["--thread", thread]
        except Exception:
            pass
        # Single instance: two backends = two translators fighting over one
        # DeepL page (and doubled bridge clients). Focus nothing — just refuse.
        try:
            if textbox_pids():
                self.log_view.append("textbox: already running (one instance only).")
                return
        except Exception:
            pass
        # Keep stderr: fatal tracebacks used to vanish into DEVNULL, which is
        # how rendering bugs shipped invisible (see translate.md self-test).
        try:
            logdir = os.path.expanduser("~/.cache/anime4k")
            os.makedirs(logdir, exist_ok=True)
            logf = open(os.path.join(logdir, "textbox.log"), "ab", buffering=0)
        except OSError:
            logf = _sp.DEVNULL
        try:
            self.textbox_proc = _sp.Popen(argv, stdout=logf, stderr=logf,
                                          stdin=_sp.DEVNULL, start_new_session=True)
            self.log_view.append("textbox: started (stderr -> ~/.cache/anime4k/textbox.log)")
        except (OSError, _sp.SubprocessError) as e:
            # Log the real reason (e.g. missing exec bit): the generic
            # warning alone once hid a Permission denied.
            self.textbox_proc = None
            self.log_view.append(f"textbox: could not open ({e})")
            QMessageBox.warning(self, "Textbox", f"Could not open the translation window:\n{e}")

    def poll_translate_status(self):
        try:
            up = translate_bridge_ok()
        except Exception:
            up = False
        self.tr_status.setText("● translation bridge (:6677)" if up else "○ bridge down")

    def preview_command(self):
        gid = self.selected_id()
        if not gid:
            return
        game = load_games().get(gid)
        if not game:
            return
        argv = build_command(game)
        QMessageBox.information(self, "Resolved command", " ".join(argv))

    def stop_game(self):
        import signal as _sig
        if self.proc is not None:
            self.log_view.append("stopping…")
            self.proc.terminate()
        # The textbox backend owns the translator + its browser; end them
        # with the session or the browser orphans and the box resurrects.
        if self.textbox_proc is not None and self.textbox_proc.poll() is None:
            self.log_view.append("stopping translation readout…")
            _kill_textbox_group(self.textbox_proc, _sig.SIGTERM)
        QTimer.singleShot(3000, self._force_stop)

    def _force_stop(self):
        import signal as _sig
        if self.proc is None:
            pass
        elif self.proc.state() != QProcess.NotRunning:
            self.proc.kill()
        if self.proc is not None:
            gid = getattr(self, "_running_gid", None)
            if gid:
                game = load_games().get(gid)
                if game:
                    if kill_strays(stray_token(game)):
                        self.log_view.append("cleaned stray processes.")
        if self.textbox_proc is not None:
            if self.textbox_proc.poll() is None:
                _kill_textbox_group(self.textbox_proc, _sig.SIGKILL)
                self.log_view.append("translation readout stopped.")
            self.textbox_proc = None
        # Orphaned translator browsers (backend died without cleanup): only
        # the isolated CDP profile ever matches — real browsers are safe.
        try:
            r = subprocess.run(["pkill", "-f", _textbox_brave_pattern()],
                               capture_output=True, timeout=10)
            if r.returncode == 0:
                self.log_view.append("translator browser stopped.")
        except (OSError, subprocess.SubprocessError):
            pass

    def _read_log(self):
        if self.proc is not None:
            self.log_view.append(str(self.proc.readAllStandardOutput(), "utf-8", "replace").rstrip())

    def _finished(self, code, status):
        self.log_view.append(f"\n[exited with code {code}]")
        self.status_label.setText("Idle.")
        self.stop_btn.setEnabled(False)
        self.proc = None
        gid = self._running_gid
        self._running_gid = None
        if getattr(self, "_running_translate", False):
            self._running_translate = False
            # A translate session just ended: if the user clicked "Save
            # hook(s)" in Textractor (Setup), record those codes into the
            # library automatically — nothing is ever hand-copied.
            if gid:
                game = load_games().get(gid) or {}
                if game.get("path"):
                    try:
                        r = subprocess.run(
                            [sys.executable,
                             os.path.join(TRANSLATE_DIR, "harvest-hooks.py"),
                             "--exe", game["path"], "--game", gid],
                            capture_output=True, text=True, timeout=30)
                        for line in (r.stdout + r.stderr).splitlines():
                            if line.strip():
                                self.log_view.append(line)
                    except (OSError, subprocess.SubprocessError):
                        pass
                    self.refresh_list()
                    self.show_details()

    def open_settings(self):
        dlg = SettingsDialog(self)
        if dlg.exec() != QDialog.Accepted:
            return
        cfg = dlg.result_config(load_config())
        save_config(cfg)
        apply_theme(QApplication.instance(), cfg.get("gui.theme", "System"))
        QMessageBox.information(
            self, "Settings",
            "Saved. Prefix/Proton/layer changes apply to the next launch.")


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Anime4K Launcher")
    apply_theme(app, load_config().get("gui.theme", "System"))
    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
