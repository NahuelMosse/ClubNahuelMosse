#!/bin/sh
# Runs everything that counts. Exits non-zero if any step fails.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)

cd "$root/apps/api"
uv run ruff check .
uv run mypy app
uv run pytest

if [ -d "$root/apps/mobile" ]; then
  cd "$root/apps/mobile"
  flutter analyze
  # The tests are frozen when they are committed red: their format is not checked.
  dart format --output=none --set-exit-if-changed lib
  flutter test
fi
