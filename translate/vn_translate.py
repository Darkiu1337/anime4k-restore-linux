#!/usr/bin/env python3
"""vn_translate.py — hook line in, translation out.
Reads JA lines from the Textractor websocket (or stdin), translates via
Brave-CDP DeepL with DLX fallback, prints EN and forwards JA:/EN: pairs
to the overlay over stdout when piped.
Usage:
  vn_translate.py [--filter SUFFIX] [--thread NAME|NUM|*] [--no-cdp] [--print-only]
  echo "おはよう" | vn_translate.py --print-only   # headless check, no hook needed
"""
import os
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, HERE)

from cfg import load_config
CONFIG = load_config()

try:
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
except Exception:
    pass


def make_translator(use_cdp=True):
    cdp = None
    if use_cdp:
        try:
            from deepl_cdp import BraveCDP
            cdp = BraveCDP(CONFIG)
            print("translate: Brave CDP ready", flush=True)
        except Exception as e:
            print(f"translate: CDP unavailable ({e})", flush=True)

    # DLX is an opt-in, experimental fallback that needs a local server.
    dlx = None
    if CONFIG.get("dlx_enabled"):
        from deepl_dlx import translate as dlx

    def tr(text):
        if cdp is not None:
            try:
                return cdp.translate(text), "cdp"
            except Exception as e:
                print(f"translate: CDP failed ({e})", flush=True)
        if dlx is not None:
            try:
                return dlx(text, CONFIG["dlx_url"], CONFIG["srclang"].upper(),
                           CONFIG["tgtlang"].upper()), "dlx"
            except Exception as e:
                print(f"translate: DLX failed ({e})", flush=True)
        return "[DeepL unavailable — retrying]", "none"
    return tr


def main():
    args = sys.argv[1:]
    filt = ""
    if "--filter" in args:
        filt = args[args.index("--filter") + 1]
    thread = "*"
    if "--thread" in args and args.index("--thread") + 1 < len(args):
        thread = args[args.index("--thread") + 1]
    use_cdp = "--no-cdp" not in args
    tr = make_translator(use_cdp)
    if not sys.stdin.isatty():  # piped JA lines (or hook_client output)
        last_in = ""
        for line in sys.stdin:
            line = line.strip()
            if not line or line.startswith(("hook:", "RAW:", "translate:")):
                continue
            if line.startswith("TEXT:"):
                line = line[5:].strip()
            elif line.startswith("[") and "] " in line:
                hook, line = line[1:].split("] ", 1)
                if filt and filt not in hook:
                    continue
            elif line.startswith("JA:"):
                line = line[3:].strip()
            if not line or line == last_in:
                continue
            last_in = line
            out, via = tr(line)
            print(f"JA: {line}", flush=True)
            print(f"EN[{via}]: {out}", flush=True)
        return
    # Direct bridge listen: route through hook_client so vn-bridge v2 thread
    # tags are parsed/filtered (default follows Textractor's own selection).
    from hook_client import listen
    def on_ja(ja):
        out, via = tr(ja)
        print(f"JA: {ja}", flush=True)
        print(f"EN[{via}]: {out}", flush=True)
    listen(CONFIG["hook_url"], filt, False, False, on_message=on_ja, thread=thread)


if __name__ == "__main__":
    main()
