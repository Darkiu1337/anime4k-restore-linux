#!/usr/bin/env python3
"""deepl_dlx.py — DeepLX/DLX HTTP fallback (Luna use which=0 equivalent).
POST {text, source_lang, target_lang} to a local DLX server.
Server: docker run -d -p 1188:1188 ghcr.io/owo-network/deeplx:latest
"""
import requests


def translate(text, dlx_url="http://localhost:1188/translate",
              source_lang="JA", target_lang="EN", timeout=20):
    r = requests.post(dlx_url, json={"text": text, "source_lang": source_lang,
                                     "target_lang": target_lang}, timeout=timeout)
    r.raise_for_status()
    return r.json()["data"]


if __name__ == "__main__":
    import sys
    print(translate(sys.argv[1] if len(sys.argv) > 1 else "おはよう"))
