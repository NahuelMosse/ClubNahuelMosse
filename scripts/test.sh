#!/bin/sh
# Corre todo lo que cuenta. Sale distinto de cero si falla cualquier paso.
set -e
raiz=$(cd "$(dirname "$0")/.." && pwd)

cd "$raiz/apps/api"
uv run ruff check .
uv run mypy --strict app
uv run pytest

if [ -d "$raiz/apps/mobile" ]; then
  cd "$raiz/apps/mobile"
  flutter analyze
  dart format --set-exit-if-changed lib test integration_test
  flutter test
fi
