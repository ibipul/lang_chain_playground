#!/usr/bin/env bash
# One-command launcher for the my-language demo (Mark Anthony role-play assistant on LangServe).
# Sets up Python and Poetry, installs dependencies, checks the OpenAI key, starts the server.
# Usage: ./run.sh                 (opens http://localhost:8000/assistant/playground, or the next free port)
#        PORT=9000 ./run.sh       (use exactly this port)
#        ./run.sh --install       (developer setup: dev tools, my-app, direnv; doesn't start the server)
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
POETRY_VERSION=2.2.1

INSTALL=""
case "${1:-}" in
  "") ;;
  --install) INSTALL=1 ;;
  *) echo "Usage: ./run.sh [--install]"; exit 1 ;;
esac
STEPS=5; [ -n "$INSTALL" ] && STEPS=4

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n  \033[31m✗ %s\033[0m\n\n' "$*" >&2; exit 1; }
# Yes/no question; answers "no" when there's no terminal to ask in.
ask()  { [ -t 0 ] || return 1; printf '  %s [y/N] ' "$1"; read -r reply; [[ "$reply" =~ ^[Yy] ]]; }

# ---------------------------------------------------------------- 1. Python
say "[1/$STEPS] Checking Python"
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
say "[2/$STEPS] Setting up dependencies"
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

if [ -n "$INSTALL" ]; then
  # Dev tools (langchain-cli, pytest) for my-language, then my-app into the same .venv.
  echo "  Installing dev tools for my-language ..."
  (cd my-language && VIRTUAL_ENV="$ROOT/.venv" POETRY_VIRTUALENVS_CREATE=false \
    "$ROOT/.poetry/bin/poetry" install --no-interaction) \
    || die "Dev tool install failed (see Poetry's message above). Run ./run.sh --install again."
  ok "my-language: packages and dev tools in .venv"

  say "[3/$STEPS] Setting up my-app (same .venv) and checking versions match"
  (cd my-app && VIRTUAL_ENV="$ROOT/.venv" POETRY_VIRTUALENVS_CREATE=false \
    "$ROOT/.poetry/bin/poetry" install --no-interaction) \
    || die "my-app install failed (see Poetry's message above). Run ./run.sh --install again."
  ok "my-app: installed in .venv"
  # All projects share one .venv, so their three lock files must agree on every package they have in common.
  .venv/bin/python - <<'PYEOF' || warn "Lock files disagree (listed above). Run 'poetry lock --regenerate' in my-language/packages/my-assistant, my-app and my-language, then ./run.sh --install again."
import tomllib, sys
locks = {"my-language": "my-language/poetry.lock", "my-assistant": "my-language/packages/my-assistant/poetry.lock", "my-app": "my-app/poetry.lock"}
v = {n: {p["name"]: p["version"] for p in tomllib.load(open(f, "rb"))["package"]} for n, f in locks.items()}
bad = sorted({p for a in v for b in v for p in v[a].keys() & v[b].keys() if v[a][p] != v[b][p]})
for p in bad:
    print(f"  \033[33m!\033[0m {p}: " + ", ".join(f"{n} {v[n][p]}" for n in v if p in v[n]))
if bad:
    sys.exit(1)
print(f"  \033[32m✓\033[0m Lock files agree (LangChain {v['my-language']['langchain']}, langchain-core {v['my-language']['langchain-core']})")
PYEOF
  [ -f my-app/.envrc ] && warn "my-app/.envrc is no longer needed (my-app now uses the shared .venv). Delete it and my-app/.venv."

  # ---------------------------------------------------------------- direnv
  say "[4/$STEPS] Setting up direnv"
  if ! command -v direnv >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1 && ask "direnv isn't installed. Install it with Homebrew?"; then
      brew install direnv || die "brew install direnv failed (see above)."
    else
      warn "direnv isn't installed. Get it from https://direnv.net/docs/installation.html and run ./run.sh --install again."
    fi
  fi
  if command -v direnv >/dev/null 2>&1; then
    ok "direnv $(direnv version) installed"
    SH="$(basename "${SHELL:-}")"
    case "$SH" in
      zsh)  RC="$HOME/.zshrc" ;;
      bash) RC="$HOME/.bashrc" ;;
      *)    RC="" ;;
    esac
    HOOK="eval \"\$(direnv hook $SH)\""
    if [ -z "$RC" ]; then
      warn "Add direnv's hook for your shell ($SH) by hand: https://direnv.net/docs/hook.html"
    elif grep -q 'direnv hook' "$RC" 2>/dev/null; then
      ok "Shell hook already in $RC"
    elif ask "Add direnv's shell hook to $RC?"; then
      printf '\n# direnv: load .envrc files when you cd into a folder\n%s\n' "$HOOK" >> "$RC"
      ok "Added to $RC: $HOOK"
      warn "Open a new terminal (or run: exec $SH) so the hook takes effect."
    else
      warn "Add this line to $RC yourself:  $HOOK"
    fi
    if [ -f .envrc ]; then
      ok ".envrc already exists (left as is)"
    else
      cp .envrc.example .envrc && ok "Created .envrc from .envrc.example"
    fi
    direnv allow "$ROOT" && ok "Allowed .envrc"
  fi

  [ -f .env ] || warn "No .env yet: cp .env.example .env and add your OpenAI API key."
  printf '\n  \033[1;32m●  Developer setup done.\033[0m\n'
  echo "     cd into this folder (or my-language/) and the project venv, Poetry and your .env keys load automatically."
  echo "     Start the demo with ./run.sh, or by hand: cd my-language && langchain serve"
  echo
  exit 0
fi

# ---------------------------------------------------------------- 3. API key
# The assistant embeds its George Orwell notes with OpenAI when the server starts, so a working key is required.
say "[3/$STEPS] Checking the OpenAI API key"
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
say "[4/$STEPS] Finding a port"
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
say "[5/$STEPS] Starting the LangServe server"
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
