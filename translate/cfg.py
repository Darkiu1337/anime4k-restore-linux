#!/usr/bin/env python3
"""cfg.py — shared translator settings loader.

Resolution order: translate/config.json (user overrides, seeded by
install.sh) -> translate/config.json.sample (shipped defaults) ->
builtin DEFAULTS. Never raises on missing files, so textbox.py and
vn_translate.py launch on a fresh clone.
"""
import json
import os

# Entry points may run through ~/.local/bin symlinks: resolve them, or the
# sample/override lookup lands next to the link instead of this directory.
HERE = os.path.dirname(os.path.realpath(__file__))

DEFAULTS = {
    "hook_url": "ws://localhost:6677",
    "hook_filter": "",
    "debugport": 9222,
    "brave_bin": "/usr/bin/brave-origin",
    "brave_profile": "~/.cache/vn-translate/brave-cdp-profile",
    "deepl_url": "https://www.deepl.com/en/translator",
    "srclang": "ja",
    "tgtlang": "en",
    "dlx_url": "http://localhost:1188/translate",
    "cdp_timeout": 30,
}


def load_config():
    cfg = dict(DEFAULTS)
    for name in ("config.json", "config.json.sample"):
        try:
            with open(os.path.join(HERE, name), encoding="utf-8") as f:
                cfg.update(json.load(f))
            break
        except (OSError, ValueError):
            continue
    for key in ("brave_profile",):
        val = cfg.get(key)
        if isinstance(val, str):
            cfg[key] = os.path.expanduser(os.path.expandvars(val))
    return cfg
