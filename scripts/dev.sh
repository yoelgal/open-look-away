#!/usr/bin/env bash
#
# The edit → run loop: debug build, install a *separate* dev copy, relaunch it.
#
#   scripts/dev.sh                    # rebuild and relaunch in the background
#   DEV_FOREGROUND=1 scripts/dev.sh   # ... and bring it to the front
#
# Does not touch the app from install.sh. Dev lives in ~/Applications with its own
# bundle id and prefs domain, so both can run and the real one is never the thing
# you just broke.
#
# Overrides:
#   OLA_DEV_APP=/path/to.app     default ~/Applications/open-lookaway-dev.app
#   OLA_DEV_NAME=name            menu bar / Dock name (default open-lookaway-dev)
#   OLA_DEV_BUNDLE_ID=id         default dev.openlookaway.app-dev
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${OLA_DEV_APP:-$HOME/Applications/open-lookaway-dev.app}"
DEV_NAME="${OLA_DEV_NAME:-open-lookaway-dev}"
DEV_BUNDLE_ID="${OLA_DEV_BUNDLE_ID:-dev.openlookaway.app-dev}"
EXEC_PATH="$TARGET/Contents/MacOS/OpenLookAway"

OLA_APP_NAME="$DEV_NAME" \
OLA_BUNDLE_ID="$DEV_BUNDLE_ID" \
OLA_SOURCE_ROOT="$ROOT" \
    "$ROOT/scripts/build-app.sh" debug

# Path match only — never pkill -x OpenLookAway (that kills the installed app).
if pkill -f "^$EXEC_PATH$" 2>/dev/null; then
    echo "==> stopped the running dev app"
    for _ in $(seq 20); do
        pgrep -f "^$EXEC_PATH$" >/dev/null || break
        sleep 0.25
    done
fi

echo "==> installing to $TARGET"
parent="$(dirname "$TARGET")"
mkdir -p "$parent"
[ -w "$parent" ] || { echo "dev: $parent is not writable — set OLA_DEV_APP" >&2; exit 1; }
rm -rf "$TARGET"
ditto "$ROOT/dist/OpenLookAway.app" "$TARGET"

# -n always starts a new instance after we replaced the bundle.
# -g keeps focus where you are unless DEV_FOREGROUND=1.
args=(-n)
[ "${DEV_FOREGROUND:-0}" = "1" ] || args+=(-g)
open "${args[@]}" "$TARGET"

echo "OK: running $TARGET"
echo "    prefs domain: $DEV_BUNDLE_ID"
echo "    tip: defaults delete $DEV_BUNDLE_ID   # reset setup"
