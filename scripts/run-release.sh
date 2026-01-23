#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_ENV="PYTHONPATH=server"
BACKEND_CMD="$PYTHON_ENV python3 -m uvicorn server.app.main:app --reload --host 127.0.0.1 --port 8000"
UVICORN_PID_FILE="$ROOT/.uvicorn.pid"

function ensure_uvicorn() {
  if ! python3 -m pip show uvicorn >/dev/null 2>&1; then
    echo "⚠️  uvicorn non è installato via pip; installalo con"
    echo "    python3 -m pip install -r server/requirements.txt"
    exit 1
  fi
}

function start_backend() {
  if [[ -f "$UVICORN_PID_FILE" ]]; then
    local pid
    pid="$(cat "$UVICORN_PID_FILE")"
    if kill -0 "$pid" >/dev/null 2>&1; then
      echo "🧠 Backend FastAPI già avviato (pid=$pid)."
      return
    else
      rm -f "$UVICORN_PID_FILE"
    fi
  fi
  echo "🚀 Avvio mock FastAPI..."
  (cd "$ROOT" && exec bash -c "$BACKEND_CMD" >"$ROOT/logs/backend.log" 2>&1) &
  echo $! >"$UVICORN_PID_FILE"
  echo "   PID backend: $(cat "$UVICORN_PID_FILE")"
  echo "   log: $ROOT/logs/backend.log"
  sleep 2
}

function ensure_log_dir() {
  mkdir -p "$ROOT/logs"
}

function run_reset_ios_build() {
  echo "🧹 Eseguo reset iOS build..."
  (cd "$ROOT" && ./scripts/reset-ios-build.sh)
}

function finish_steps() {
  echo
  echo "✅ Ambiente pronto."
  echo "   - backend: http://127.0.0.1:8000 (token changeme)"
  echo "   - .env aggiornato per puntare al mock"
  echo "   - Ora apri ios/Runner.xcworkspace e premi ▶️ sul tuo device."
  echo "   - Per pulire il log backend: kill \$(cat $UVICORN_PID_FILE) && rm $UVICORN_PID_FILE"
}

ensure_uvicorn
ensure_log_dir
start_backend
run_reset_ios_build
finish_steps
