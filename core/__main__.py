"""core CLI — the shell-facing surface used by the TUI.

Commands: launch, add, set, tset, remove, gpus. The GUI imports the modules
directly; this exists so the bash frontend shares one store/validation path.
"""
import argparse
import os
import sys


def _launch(args):
    from . import commands, store
    game = store.load_games().get(args.gid)
    if not game:
        print(f"error: unknown game id '{args.gid}'", file=sys.stderr)
        return 1
    path = game.get("path", "")
    if not os.path.exists(path):
        print(f"error: path no longer exists: {path}", file=sys.stderr)
        return 1
    tr = game.get("translate") or {}
    if game.get("runner", "proton") == "proton" and tr.get("enabled") == "1":
        hook_saved = bool((tr.get("hook_code") or "").strip()
                          or (tr.get("thread") or "").strip())
        setup = not hook_saved
        if setup:
            print(f"no hook recorded for '{args.gid}': launching SETUP "
                  "(pick the story thread in the in-app picker)")
        argv = commands.build_translate_command(game, args.gid, setup=setup)
    else:
        argv = commands.build_command(game)
    os.execv(argv[0], argv)
    return 0


def _add(args):
    from . import library, store
    data = {
        "name": args.name,
        "runner": args.runner,
        "path": args.path,
        "variant": args.variant,
        "gpu": args.gpu,
        "fps": args.fps,
        "hud": args.hud,
        "prefix_mode": args.prefix_mode,
        "lang": args.lang,
        "translate": {
            "enabled": args.tr_enabled,
            "hook_code": args.tr_hook,
            "hook_mode": "unknown",
        },
    }
    reason = library.validate_entry(data)
    if reason:
        print(f"error: {reason}", file=sys.stderr)
        return 1
    games = store.load_games()
    print(store.new_game(games, data))
    return 0


def _set(args):
    from . import store
    games = store.load_games()
    if args.gid not in games:
        print(f"error: unknown game id '{args.gid}'", file=sys.stderr)
        return 1
    games[args.gid][args.field] = args.value
    store.save_games(games)
    return 0


def _tset(args):
    from . import store
    games = store.load_games()
    if args.gid not in games:
        print(f"error: unknown game id '{args.gid}'", file=sys.stderr)
        return 1
    games[args.gid].setdefault("translate", {})[args.field] = args.value
    store.save_games(games)
    return 0


def _remove(args):
    from . import store
    store.remove_game(args.gid)
    return 0


def _gpus(args):
    from . import system
    for name in system.list_gpus():
        print(name)
    return 0


def build_parser():
    ap = argparse.ArgumentParser(prog="python3 -m core")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("launch")
    p.add_argument("gid")
    p.set_defaults(fn=_launch)

    p = sub.add_parser("add")
    p.add_argument("--name", required=True)
    p.add_argument("--runner", required=True)
    p.add_argument("--path", required=True)
    p.add_argument("--variant", default="L")
    p.add_argument("--gpu", default="auto (discrete GPU preferred)")
    p.add_argument("--fps", default="60")
    p.add_argument("--hud", default="0")
    p.add_argument("--prefix-mode", default="shared")
    p.add_argument("--lang", default="")
    p.add_argument("--tr-enabled", default="0")
    p.add_argument("--tr-hook", default="")
    p.set_defaults(fn=_add)

    for name, fn in (("set", _set), ("tset", _tset)):
        p = sub.add_parser(name)
        p.add_argument("gid")
        p.add_argument("field")
        p.add_argument("value")
        p.set_defaults(fn=fn)

    p = sub.add_parser("remove")
    p.add_argument("gid")
    p.set_defaults(fn=_remove)

    p = sub.add_parser("gpus")
    p.set_defaults(fn=_gpus)
    return ap


def main():
    args = build_parser().parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
