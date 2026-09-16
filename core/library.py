import os
import re


def slugify(name):
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "game"


def validate_entry(data):
    """None when valid, else a user-facing reason string."""
    if not data.get("path") or not os.path.exists(data["path"]):
        return "That path does not exist."
    if data.get("runner") == "rpgmaker" and not os.path.isdir(data["path"]):
        return ("The rpgmaker runner needs the game folder, not a file.\n"
                "Use Detect (or pick the folder containing www/).")
    return None


def normalize_edit(data, prev):
    data["runner"] = prev.get("runner", data.get("runner", "proton"))
    tr_prev = prev.get("translate", {})
    tr = data.setdefault("translate", {})
    tr["hook_mode"] = tr_prev.get("hook_mode", "unknown")
    tr["thread"] = tr_prev.get("thread", "")
    return data
