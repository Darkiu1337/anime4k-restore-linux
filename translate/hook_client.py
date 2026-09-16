#!/usr/bin/env python3
"""hook_client.py — listen to Textractor's websocket bridge (ws://localhost:6677).
Dumps raw messages; --filter keeps only lines whose hook/thread matches a suffix
(e.g. the story hook code pasted from Textractor); --thread keeps only a
vn-bridge v2 thread tag (name, number, or hex addr; "*" follows Textractor's
own selection, the default).
"""
import json
import re
import sys
import time

import websocket


def _ts():
    return time.strftime("%H:%M:%S")


ZWSP = "\u200b"  # U+200B zero-width space, explicit escape

# vn-bridge v2 tag: ~#<number>[* if Textractor-selected]~<hookaddr-hex>~<name>~<text>
THREAD_TAG_RE = re.compile(r"^~#(\d+)(\*?)~([0-9A-Fa-f]+)~([^~]*)~(.*)$", re.DOTALL)


def parse_thread(msg):
    """Split a tagged message -> (meta dict, text). Untagged (stock bridge)
    messages return (None, msg unchanged)."""
    m = THREAD_TAG_RE.match(msg)
    if not m:
        return None, msg
    num, sel, addr, name, text = m.groups()
    return {"number": int(num), "selected": sel == "*",
            "addr": addr.upper(), "name": name or "?"}, text


def thread_match(meta, thread):
    """thread selector: "" or "*" follows Textractor's selection (untagged
    stock messages always pass); otherwise match name, number, or addr."""
    if not thread or thread == "*":
        return meta is None or meta["selected"]
    if meta is None:
        return True
    t = thread.strip()
    return t == meta["name"] or t == str(meta["number"]) or t.upper() == meta["addr"]


def clean_ja(msg):
    """Story source = text before the zero-width space; translate-extension
    output (e.g. Tajik) after it is dropped. Newlines become spaces so one
    ws message = one JA: line downstream."""
    ja = msg.split(ZWSP)[0]
    ja = " ".join(ja.split())
    return ja


def listen(url, hook_filter="", raw=False, pipe=False, on_message=None,
           thread="*", on_tagged=None):
    """If on_message is given, call on_message(ja_text) per cleaned message
    (deduped) instead of printing; used by the overlay's embedded pipeline.
    If on_tagged is given, call on_tagged(meta, ja_text) instead (meta is the
    v2 thread tag dict, or None for untagged stock messages). `thread`
    selects which thread flows (see thread_match)."""
    ws = websocket.create_connection(url, timeout=None)
    print(f"hook [{_ts()}] connected to {url}", flush=True)
    last = ("", "")
    while True:
        try:
            msg = ws.recv()
        except Exception as e:
            # Timestamped: drop timing is the first clue when diagnosing
            # silent textboxes (transport flap vs no sentences).
            print(f"hook [{_ts()}] connection closed: {e}", flush=True)
            return
        if raw:
            print(f"RAW: {msg}", flush=True)
            continue
        if pipe or on_message or on_tagged:
            meta, text = parse_thread(msg)
            if not thread_match(meta, thread):
                continue
            ja = clean_ja(text)
            key = (meta["number"] if meta else "", ja)
            if ja and key != last:
                last = key
                if on_tagged:
                    on_tagged(meta, ja)
                elif on_message:
                    on_message(ja)
                else:
                    print(f"JA: {ja}", flush=True)
            continue
        try:
            obj = json.loads(msg)
        except Exception:
            print(f"TEXT: {msg}", flush=True)
            continue
        text = obj.get("text") or obj.get("sentence") or msg
        hook = obj.get("hook") or obj.get("name") or obj.get("thread") or ""
        if hook_filter and hook_filter not in str(hook):
            continue
        print(f"[{hook}] {text}", flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    filt = args[0] if args and not args[0].startswith("-") else ""
    raw = "--raw" in args
    pipe = "--pipe" in args
    thread = "*"
    if "--thread" in args:
        ti = args.index("--thread") + 1
        if ti < len(args):
            thread = args[ti]
    url = "ws://localhost:6677"
    for a in args:
        if a.startswith("ws://"):
            url = a
    listen(url, filt, raw, pipe, thread=thread)
