#!/usr/bin/env bash
# One-command launcher for the my-language demo (Mark Anthony role-play assistant on LangServe).
# Sets up Python and Poetry, installs dependencies, checks the OpenAI key, starts the server.
# Usage: ./run.sh                 (opens http://localhost:8000/assistant/playground, or the next free port)
#        PORT=9000 ./run.sh       (use exactly this port)
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
POETRY_VERSION=2.2.1

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n  \033[31m✗ %s\033[0m\n\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 1. Python
say "[1/5] Checking Python"
PY=""
for candidate in "${PYTHON:-}" python3 python3.13 python3.12 python3.11; do
  [ -n "$candidate" ] || continue
  if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then
    PY="$candidate"; break
  fi
done
[ -n "$PY" ] || die "Python 3.11 or newer is required (found: $(python3 --version 2>&1)). Install it, or run: PYTHON=/path/to/python3.11 ./run.sh"
ok "Using $("$PY" --version 2>&1)"

# ---------------------------------------------------------------- 2. Dependencies
# Poetry lives in its own venv (.poetry) so its packages never clash with the app's (.venv).
say "[2/5] Setting up dependencies"
if [ ! -x .poetry/bin/poetry ]; then
  echo "  Installing Poetry $POETRY_VERSION into .poetry ..."
  { "$PY" -m venv .poetry && .poetry/bin/python -m pip install --disable-pip-version-check -q "poetry==$POETRY_VERSION"; } \
    || die "Could not install Poetry. Check your internet connection, delete the .poetry folder and run ./run.sh again."
fi
if [ ! -x .venv/bin/python ]; then
  echo "  Creating a virtual environment in .venv ..."
  "$PY" -m venv .venv || die "Could not create the virtual environment. Delete the .venv folder and run ./run.sh again."
fi
if [ ! -f .venv/.deps-installed ] || [ my-language/poetry.lock -nt .venv/.deps-installed ]; then
  echo "  Installing packages (first run only; usually 1-3 minutes, longer on a slow network)."
  echo
  (cd my-language && VIRTUAL_ENV="$ROOT/.venv" POETRY_VIRTUALENVS_CREATE=false \
    "$ROOT/.poetry/bin/poetry" install --only main --no-interaction) \
    || die "Package install failed (see Poetry's message above). Check your internet connection and run ./run.sh again. If it keeps failing, delete the .venv folder and retry."
  touch .venv/.deps-installed
  echo
  ok "Packages installed"
else
  ok "Packages already installed (skipping)"
fi

# ---------------------------------------------------------------- 3. API key
# The assistant embeds its George Orwell notes with OpenAI when the server starts, so a working key is required.
say "[3/5] Checking the OpenAI API key"
[ -f .env ] || die "Missing .env. Copy .env.example to .env and add your OpenAI API key."
set -a; . ./.env; set +a
KEY="${OPENAI_API_KEY:-}"
{ [ -z "$KEY" ] || [[ "$KEY" == *PASTE* ]]; } && die "No API key in .env (OPENAI_API_KEY is empty). Get one at https://platform.openai.com/api-keys"
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -H "Authorization: Bearer $KEY" "${OPENAI_BASE_URL:-https://api.openai.com/v1}/models")
case "$CODE" in
  200) ok "API key accepted by OpenAI" ;;
  401) die "OpenAI rejected the key in .env (HTTP 401). Check OPENAI_API_KEY, or create a new key at https://platform.openai.com/api-keys" ;;
  000) warn "Could not reach OpenAI to check the key. Is the internet connection working?" ;;
  *)   warn "OpenAI answered HTTP $CODE when checking the key; trying to start anyway." ;;
esac
[ "${LANGSMITH_TRACING:-}" = "true" ] && ok "LangSmith tracing on (project: ${LANGSMITH_PROJECT:-default})"

# ---------------------------------------------------------------- 4. Port
say "[4/5] Finding a port"
port_free() { .venv/bin/python -c 'import socket,sys; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(("127.0.0.1", int(sys.argv[1])))' "$1" 2>/dev/null; }
is_this_app() { curl -s --max-time 2 "http://127.0.0.1:$1/assistant/input_schema" 2>/dev/null | grep -q '"personality"'; }
who_has() { command -v lsof >/dev/null && lsof -nP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1" (PID "$2")"}'; }
open_url() {
  [ -n "${NO_BROWSER:-}" ] && return
  command -v open >/dev/null && open "$1" >/dev/null 2>&1
  command -v xdg-open >/dev/null && xdg-open "$1" >/dev/null 2>&1
}

if [ -n "${PORT:-}" ]; then
  if ! port_free "$PORT"; then
    if is_this_app "$PORT"; then
      die "This app is already running on port $PORT: open http://localhost:$PORT/assistant/playground. To restart it, press Ctrl+C in the terminal where it runs (or: kill $(lsof -ti tcp:$PORT 2>/dev/null | head -1)), then run ./run.sh again."
    fi
    die "Port $PORT is in use by another program $(who_has "$PORT"). Pick another, e.g.: PORT=9000 ./run.sh"
  fi
else
  # Walk up from 8000: use the first free port, but if an earlier run of this app is found, point to it.
  PORT=8000
  while ! port_free "$PORT"; do
    if is_this_app "$PORT"; then
      warn "An earlier run of this app is already serving http://localhost:$PORT/assistant/playground"
      warn "Just use that one. To restart instead, stop it first (Ctrl+C in its terminal, or: kill $(lsof -ti tcp:$PORT 2>/dev/null | head -1)), then run ./run.sh again."
      open_url "http://localhost:$PORT/assistant/playground"
      echo; exit 0
    fi
    warn "Port $PORT is busy (used by $(who_has "$PORT")); trying $((PORT + 1))"
    PORT=$((PORT + 1))
    [ "$PORT" -le 8020 ] || die "No free port between 8000 and 8020. Free one up, or run: PORT=9000 ./run.sh"
  done
fi
ok "Using port $PORT"

# ---------------------------------------------------------------- 5. Server
say "[5/5] Starting the LangServe server"
(cd my-language && exec "$ROOT/.venv/bin/python" -m uvicorn app.server:app --host 127.0.0.1 --port "$PORT" --log-level warning) &
SERVER_PID=$!
trap 'echo; echo "  Stopping..."; kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; exit 0' INT TERM

for _ in $(seq 1 90); do
  kill -0 $SERVER_PID 2>/dev/null || die "The server stopped during startup (see the error above)."
  is_this_app "$PORT" && break
  sleep 1
done
is_this_app "$PORT" || { kill $SERVER_PID 2>/dev/null; die "The server did not respond within 90 seconds (see any error above)."; }

URL="http://localhost:$PORT/assistant/playground/"
printf '\n  \033[1;32m●  Ready:  %s\033[0m\n' "$URL"
echo "     Chat playground (opening automatically if possible)."
echo "     API docs:  http://localhost:$PORT/docs"
echo "     Leave this terminal open while you use the app. Press Ctrl+C to stop."
echo
open_url "$URL"
wait $SERVER_PID
