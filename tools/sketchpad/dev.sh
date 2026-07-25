#!/usr/bin/env bash
# Checkpoint UI sketchpad — install on first run, then serve.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d node_modules ]; then
  echo "==> installing deps"
  bun install
fi

echo "==> sketchpad on http://localhost:5273"
bun run dev
