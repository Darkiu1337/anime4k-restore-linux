"""core CLI — launch <id>: build the argv for a library entry and exec it.
Single source of launch argv (TUI cmd_launch delegates here)."""
import os
import sys


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "launch":
        print("usage: python3 -m core launch <game-id>", file=sys.stderr)
        sys.exit(2)
    gid = sys.argv[2]

    from . import commands, store

    games = store.load_games()
    game = games.get(gid)
    if not game:
        print(f"error: unknown game id '{gid}'", file=sys.stderr)
        sys.exit(1)
    path = game.get("path", "")
    if not os.path.exists(path):
        print(f"error: path no longer exists: {path}", file=sys.stderr)
        sys.exit(1)

    runner = game.get("runner", "proton")
    tr = game.get("translate") or {}
    if runner == "proton" and tr.get("enabled") == "1":
        setup = not tr.get("hook_code", "").strip()
        if setup:
            print(f"no hook recorded for '{gid}': launching SETUP (pick the story thread in Textractor)")
        argv = commands.build_translate_command(game, gid, setup=setup)
    else:
        argv = commands.build_command(game)
    os.execv(argv[0], argv)


if __name__ == "__main__":
    main()
