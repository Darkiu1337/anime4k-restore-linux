import json
import os
import shutil

from . import paths
from .library import slugify


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
    return load_json(paths.GAMES_JSON, {}).get("games", {})


def save_games(games):
    if os.path.isfile(paths.GAMES_JSON):
        try:
            shutil.copyfile(paths.GAMES_JSON, paths.GAMES_JSON + ".bak")
        except OSError:
            pass
    save_json(paths.GAMES_JSON, {"games": games})


def load_config():
    return load_json(paths.CONFIG_JSON, {})


def save_config(cfg):
    save_json(paths.CONFIG_JSON, cfg)


def new_game(games, data):
    gid = unique_id(games, slugify(data.get("name", "")))
    games[gid] = data
    save_games(games)
    return gid


def update_game(games, gid, data):
    games[gid] = data
    save_games(games)


def remove_game(gid):
    games = load_games()
    games.pop(gid, None)
    save_games(games)


def unique_id(games, base):
    base = base or "game"
    gid, n = base, 2
    while gid in games:
        gid = f"{base}-{n}"
        n += 1
    return gid
