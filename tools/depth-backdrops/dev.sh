#!/usr/bin/env bash
# Launch the depth-backdrops backend (uvicorn) and frontend (vite) together.
# Ctrl-C stops both.
set -euo pipefail

cd "$(dirname "$0")"

BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-5173}"

cleanup() {
  trap - INT TERM EXIT
  echo
  echo "stopping…"
  [[ -n "${BACKEND_PID:-}" ]] && kill "$BACKEND_PID" 2>/dev/null || true
  [[ -n "${FRONTEND_PID:-}" ]] && kill "$FRONTEND_PID" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup INT TERM EXIT

if [[ ! -d backend/models ]] || ! ls backend/models/*.mlpackage >/dev/null 2>&1; then
  echo "no Core ML model found — downloading…"
  (cd backend && uv run python -m scripts.download_model)
fi

echo "backend  → http://localhost:${BACKEND_PORT}"
(cd backend && uv run uvicorn app.main:app --reload --port "$BACKEND_PORT") &
BACKEND_PID=$!

echo "frontend → http://localhost:${FRONTEND_PORT}"
# `--` ensures the --port flag is forwarded to vite rather than consumed by bun.
(cd frontend && bun run dev -- --port "$FRONTEND_PORT") &
FRONTEND_PID=$!

wait
