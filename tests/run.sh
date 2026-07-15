#!/bin/sh
# Run smoke tests in an isolated HOME so real user data is untouched.
# Usage (needs a display): dbus-run-session -- xvfb-run -a sh tests/run.sh
set -e
cd "$(dirname "$0")/.."

HOME="$(mktemp -d)"
export HOME
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

python3 tests/test_save.py
python3 tests/test_restore.py

rm -rf "$HOME"
echo "ALL TESTS PASSED"
