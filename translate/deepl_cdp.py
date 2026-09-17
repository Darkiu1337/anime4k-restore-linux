#!/usr/bin/env python3
"""deepl_cdp.py — Luna-style DeepL browser hack, native on Linux.
Launches the configured Chromium browser (any Brave/Chromium/Chrome build;
see translate/config.json `brave_bin`) with --remote-debugging-port, drives
deepl.com via CDP: clear input, Input.insertText, poll d-textarea[1] for the
result. Port of LunaTranslator translator/cdp_helper.py + deepl_1.py.
"""
import json
import os
import subprocess
import sys
import threading
import time

import requests
import websocket

# Shared guards/helpers (safe profile check, session purge) live in core.
_REPO = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
if _REPO not in sys.path:
    sys.path.insert(0, _REPO)
from core import process as _proc  # noqa: E402


class BraveCDP:
    def __init__(self, config):
        self.config = config
        self.port = config["debugport"]
        self._id = 0
        self.lock = threading.Lock()
        self._ensure_browser()
        self.ws = self._connect()

    def _profile_dir(self):
        d = os.path.abspath(self.config["brave_profile"])
        os.makedirs(d, exist_ok=True)
        return d

    def _ensure_browser(self):
        try:
            requests.get(f"http://127.0.0.1:{self.port}/json/list", timeout=3).json()
            return
        except Exception:
            pass
        # No session restore: drop stale session state so a fresh launch never
        # reopens a pile of DeepL tabs (guarded, isolated profile only).
        _proc.purge_browser_session(self._profile_dir())
        cmd = [self.config["brave_bin"], "--no-first-run",
               "--hide-crash-restore-bubble",
               f"--remote-debugging-port={self.port}",
               "--remote-allow-origins=*",
               f"--user-data-dir={self._profile_dir()}"]
        if self.config.get("browser_hidden", True):
            cmd.append("--headless=new")
        cmd.append(self.config["deepl_url"])
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            try:
                requests.get(f"http://127.0.0.1:{self.port}/json/list", timeout=3).json()
                return
            except Exception:
                time.sleep(0.3)
        raise RuntimeError("brave CDP endpoint never came up")

    def _connect(self):
        base = f"http://127.0.0.1:{self.port}"
        infos = requests.get(f"{base}/json/list", timeout=5).json()
        target = self.config["deepl_url"].split("/en/translator")[0]
        pages = [i for i in infos
                 if i.get("type") == "page" and i.get("webSocketDebuggerUrl")]
        use = next((i for i in pages
                    if (i.get("url") or "").startswith(target)), None)
        if use is not None:
            ws = websocket.create_connection(use["webSocketDebuggerUrl"], timeout=10)
        elif pages:
            # Reuse an existing tab instead of stacking a new one.
            use = pages[0]
            ws = websocket.create_connection(use["webSocketDebuggerUrl"], timeout=10)
        else:
            ws = self._new_tab(base)
            use = {"id": None}
        self._close_other_pages(base, use.get("id"))
        self._send(ws, "Page.navigate", {"url": self.config["deepl_url"]})
        self._wait_ready(ws)
        self._activate(ws)
        return ws

    def _new_tab(self, base):
        ver = requests.get(f"{base}/json/version", timeout=5).json()
        bws = websocket.create_connection(ver["webSocketDebuggerUrl"], timeout=10)
        self._id += 1
        bws.send(json.dumps({"id": self._id, "method": "Target.createTarget",
                             "params": {"url": self.config["deepl_url"]}}))
        res = json.loads(bws.recv())
        bws.close()
        return websocket.create_connection(
            f"ws://127.0.0.1:{self.port}/devtools/page/" + res["result"]["targetId"],
            timeout=10)

    def _close_other_pages(self, base, keep_id):
        """Keep exactly one DeepL tab (docs/translate.md). Never raises."""
        try:
            extra = [t for t in requests.get(f"{base}/json/list", timeout=3).json()
                     if t.get("type") == "page" and t.get("id")
                     and t.get("id") != keep_id]
            if not extra:
                return
            ver = requests.get(f"{base}/json/version", timeout=3).json()
            bws = websocket.create_connection(ver["webSocketDebuggerUrl"], timeout=3)
            for t in extra:
                self._id += 1
                bws.send(json.dumps({"id": self._id, "method": "Target.closeTarget",
                                     "params": {"targetId": t["id"]}}))
                try:
                    bws.recv()
                except Exception:
                    pass
            bws.close()
        except Exception:
            pass

    def _activate(self, ws):
        """DeepL only translates after real user activation, which headless
        lacks; dispatch a click on the source box (harmless when visible)."""
        try:
            r = self._send(ws, "Runtime.evaluate", {"expression":
                '(() => { const el = document.querySelector("d-textarea");'
                ' if (!el) return null; const b = el.getBoundingClientRect();'
                ' return JSON.stringify({x: b.x + b.width / 2, y: b.y + b.height / 2}); })()'})
            pos = r.get("result", {}).get("value")
            if not pos:
                return
            p = json.loads(pos)
            for kind in ("mousePressed", "mouseReleased"):
                self._send(ws, "Input.dispatchMouseEvent",
                           {"type": kind, "x": p["x"], "y": p["y"],
                            "button": "left", "clickCount": 1})
        except Exception:
            pass

    def _send(self, ws, method, params):
        with self.lock:
            self._id += 1
            ws.send(json.dumps({"id": self._id, "method": method, "params": params}))
            res = json.loads(ws.recv())
        if "result" not in res:
            raise RuntimeError(f"CDP {method} failed: {res}")
        return res["result"]

    def _wait_ready(self, ws, tries=200):
        for _ in range(tries):
            try:
                r = self._send(ws, "Runtime.evaluate", {"expression": "document.readyState"})
                if r.get("result", {}).get("value") == "complete":
                    return
            except Exception:
                pass
            time.sleep(0.2)
        raise RuntimeError("deepl page never reached readyState complete")

    def evaluate(self, expr):
        return self._send(self.ws, "Runtime.evaluate", {"expression": expr})

    def wait_for_result(self, expr, timeout=30):
        for _ in range(int(timeout * 10)):
            state = self.evaluate(expr)
            if state.get("exceptionDetails"):
                raise RuntimeError(f"CDP evaluate exception: {state}")
            value = state.get("result", {}).get("value")
            if value:
                return value
            time.sleep(0.1)
        raise TimeoutError(f"no result for: {expr}")

    def send_keys(self, text):
        try:
            self._send(self.ws, "Input.insertText", {"text": text})
        except Exception:
            for char in text:  # per-char fallback, mirrors Luna
                self._send(self.ws, "Input.dispatchKeyEvent",
                           {"type": "char", "text": char, "unmodifiedText": char})

    def translate(self, content):
        ws = self.ws
        self._send(ws, "Runtime.evaluate", {"expression":
            'document.getElementsByTagName("d-textarea")[1].children[0].innerHTML = ""'})
        self._send(ws, "Runtime.evaluate", {"expression":
            'document.querySelector("#translator-source-clear-button").click()'})
        self._send(ws, "Runtime.evaluate", {"expression":
            'document.getElementsByTagName("d-textarea")[0].focus()'})
        self.send_keys(content)
        self.wait_for_result('document.getElementsByTagName("d-textarea")[1].textContent',
                             timeout=self.config.get("cdp_timeout", 30))
        return self.wait_for_result('document.getElementsByTagName("d-textarea")[1].innerText',
                                    timeout=self.config.get("cdp_timeout", 30))


if __name__ == "__main__":
    import sys
    sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
    from cfg import load_config
    print(BraveCDP(load_config()).translate(sys.argv[1] if len(sys.argv) > 1 else "おはよう"))
