from PySide6.QtCore import QObject, Signal, Property

from . import theme


class Theme(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._scheme = "dark"
        self._p = dict(theme.PALETTES["dark"])

    def _get(self, key):
        return self._p.get(key, "")

    bg = Property(str, lambda s: s._get("bg"), notify=changed)
    panel = Property(str, lambda s: s._get("panel"), notify=changed)
    panelAlt = Property(str, lambda s: s._get("panelAlt"), notify=changed)
    field = Property(str, lambda s: s._get("field"), notify=changed)
    text = Property(str, lambda s: s._get("text"), notify=changed)
    subtext = Property(str, lambda s: s._get("subtext"), notify=changed)
    faint = Property(str, lambda s: s._get("faint"), notify=changed)
    accent = Property(str, lambda s: s._get("accent"), notify=changed)
    accentText = Property(str, lambda s: s._get("accentText"), notify=changed)
    hover = Property(str, lambda s: s._get("hover"), notify=changed)
    pressed = Property(str, lambda s: s._get("pressed"), notify=changed)
    border = Property(str, lambda s: s._get("border"), notify=changed)
    danger = Property(str, lambda s: s._get("danger"), notify=changed)
    ok = Property(str, lambda s: s._get("ok"), notify=changed)
    buttonText = Property(str, lambda s: s._get("buttonText"), notify=changed)

    def _get_scheme(self):
        return self._scheme

    def _set_scheme(self, v):
        if v in theme.PALETTES and v != self._scheme:
            self._scheme = v
            self._p = dict(theme.PALETTES[v])
            self.changed.emit()

    scheme = Property(str, _get_scheme, _set_scheme, notify=changed)

    def apply_override(self, override=""):
        self._set_scheme(theme.scheme(override))
