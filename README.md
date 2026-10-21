# Hands-on  langchain

[![Python 3.11+](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![LangChain 1.4.6](https://img.shields.io/badge/LangChain-1.4.6-1C3C3C?logo=langchain&logoColor=white)](https://python.langchain.com/)
[![LangServe 0.3.3](https://img.shields.io/badge/LangServe-0.3.3-1C3C3C?logo=langchain&logoColor=white)](https://github.com/langchain-ai/langserve)
[![LangSmith 0.14.11](https://img.shields.io/badge/LangSmith-0.14.11-1C3C3C?logo=langchain&logoColor=white)](https://smith.langchain.com/)
[![OpenAI GPT-3.5 Turbo](https://img.shields.io/badge/OpenAI-GPT--3.5%20Turbo%20%2B%20Embeddings-412991)](https://platform.openai.com/docs/models)
[![FAISS](https://img.shields.io/badge/FAISS-vector%20store-0467DF?logo=meta&logoColor=white)](https://github.com/facebookresearch/faiss)
[![FastAPI 0.156.5](https://img.shields.io/badge/FastAPI-0.156.5-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Uvicorn 0.54.0](https://img.shields.io/badge/Uvicorn-0.54.0-499848?logo=gunicorn&logoColor=white)](https://www.uvicorn.org/)
[![Pydantic 2.14.1](https://img.shields.io/badge/Pydantic-2.14.1-E92063?logo=pydantic&logoColor=white)](https://docs.pydantic.dev/)
[![Poetry](https://img.shields.io/badge/Poetry-dependency%20management-60A5FA?logo=poetry&logoColor=white)](https://python-poetry.org/)
[![Docker](https://img.shields.io/badge/Docker-python%3A3.11--slim-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

## Quick start

Runs the **my-language** demo: a LangServe REST API with a chat playground where you talk to a character from a book or play (Mark Anthony from *Julius Caesar* by default), backed by a small George Orwell knowledge base.

Needs Python 3.11+, internet access and an OpenAI API key. You don't need Poetry installed; `run.sh` sets it up.

```bash
git clone https://github.com/ibipul/lang_chain_playground.git
cd lang_chain_playground
```

> [!IMPORTANT]
> **Add your OpenAI API key before the first run.** The repo doesn't include one.
>
> 1. Create a key at https://platform.openai.com/api-keys (the API needs credits on your OpenAI account).
> 2. Copy the template: `cp .env.example .env`
> 3. Open `.env` and replace `PASTE_YOUR_OPENAI_KEY_HERE` with your key:
>    ```
>    OPENAI_API_KEY=sk-...your-key...
>    ```
>
> `.env` is listed in `.gitignore`, so git won't commit your key. Don't put the key in `.env.example` or anywhere else that's tracked. LangSmith tracing is optional; fill in the `LANGSMITH_*` lines in `.env` to turn it on.

Then start the app:

```bash
./run.sh
```

`run.sh` walks through five numbered steps: check Python, install Poetry and the packages (first run only, into `.poetry` and `.venv`), check the API key with OpenAI, find a free port, start the server. When it prints **● Ready: http://localhost:8000/assistant/playground/** it opens the chat playground in your browser. Keep that terminal open; press Ctrl+C there to stop.

Other ways to use it while it runs:
- API docs: http://localhost:8000/docs
- Call it from the terminal with the `curl` example in [my-language](#my-language) below.
- `PORT=9000 ./run.sh` uses a fixed port. `NO_BROWSER=1 ./run.sh` skips opening the browser.

<details>
<summary><b>Quick Troubleshooting</b> (click to show)</summary>

| You see | What it means / what to do |
|---|---|
| `Python 3.11 or newer is required` | Install Python 3.11+, or point to one: `PYTHON=/path/to/python3.11 ./run.sh` |
| `Missing .env` / `No API key in .env` | Do the key steps in the box above. |
| `OpenAI rejected the key (HTTP 401)` | The key is wrong or was deleted. Create a new one and paste it into `.env`. |
| `Package install failed` | Usually a network problem. Run `./run.sh` again; if it keeps failing, delete `.venv` and retry. |
| `The server stopped during startup` | Read the error above it. A `429` / `insufficient_quota` error means your OpenAI account has no credits left. |
| `An earlier run of this app is already serving ...` | It's already running; use that URL, or stop it first. |

</details>

The sections below describe the two sub-projects, and [Develop with direnv](#develop-with-direnv) covers working on the code.

### Shared versions

All projects (`my-app`, `my-assistant`, `my-language`) pin the same LangChain stack, in a block marked `# Shared LangChain stack` in each `pyproject.toml`:
```
python = ">=3.11,<4.0"
langchain-core = "^1.6.12"
langchain = "^1.4.6"
langchain-openai = "^1.7.2"
langsmith = "^0.14.11"
langserve = "^0.3.3"
```
Their three `poetry.lock` files agree on every package they have in common (LangChain 1.4.6, langchain-core 1.6.12, langchain-openai 1.7.2, LangSmith 0.14.11, LangServe 0.3.3, FastAPI 0.156.5, Uvicorn 0.54.0, Pydantic 2.14.1), so everything runs from one venv. `my-assistant` also uses `langchain-community` 0.4.2 for FAISS. To upgrade, see [Changing dependencies](#changing-dependencies).

### my-app
A simple prompt|model response chain
 - `langchain template new my-app` 
 - needs OpenAI api key (get your own)
 - ensure poetry dependencies are resolved

### my-language
Setup a REST API with langchain serve. It serves a RAG based assistant, which roleplays any character from any book/play, with a personality cue, and has an context of George Orwell. It can say pessimistic stuff, if you ask it to!
 - `langchain app new my-language --package $PWD/my-assistant` 
 - `add_routes(app, my_app_chain, path="/assistant")`
 -  ensure poetry dependencied are resolved
 -  `cd my-language; langchain serve`
 - `http://127.0.0.1:8000/docs` to see all the API endpoints
 - `http://127.0.0.1:8000/assistant/playground` to get a default chat interface
 - interacting with the playground chat box UI, it will invoke the `stream` endpoint
 - if `curl` is used then it uses the `invoke` endpoint
 ```
 curl --location --request POST 'http://127.0.0.1:8000/assistant/invoke' \
--header 'Content-Type: application/json' \
--data-raw '{
    "input": {
        "question": "Hello, Anthony does the world feel like it is against you?",
        "character": "Mark Anthony",
        "title": "Julius Caesar",
        "personality": "sullen mood, rhetorical, sarcastic, and dramatic"
    }
}'
```
Reponse:
```
Oh, how astute of you to notice! Indeed, it feels as though the very world conspires against me, drowning me in a sea of treachery and deceit. The nightmare of statistics haunts my every step, twisting reality into a cruel game of numbers. But fear not, for I shall rise above this adversity with the fire of vengeance burning in my heart!

[Mood: Defiant]
```


## Develop with direnv

`./run.sh` is all you need to try the demo. This section is for working on the code: editing the chains, running tests, adding packages, or starting the server by hand with `langchain serve`.

[direnv](https://direnv.net/) loads a folder's settings when you `cd` into it and unloads them when you leave. Here it loads your keys from `.env`, puts the project's own `python`, `poetry`, `langchain` and `pytest` first on your PATH, and points Poetry at the project venv. You never run `source .venv/bin/activate` or export keys by hand.

### One-time setup

```bash
cp .env.example .env        # then add your OPENAI_API_KEY (see Quick start)
./run.sh --install
```

`./run.sh --install` sets everything up and exits without starting the server:

1. Installs Poetry into `.poetry`, and `my-language` plus its dev tools (`langchain-cli`, `pytest`) into `.venv`.
2. Installs `my-app` into the same `.venv`, and checks that the three lock files agree on every shared package. If they don't, it lists each package and its versions.
3. Sets up direnv:
   - If direnv is missing, offers to install it with Homebrew (otherwise see https://direnv.net/docs/installation.html).
   - Offers to add direnv's hook line to `~/.zshrc` or `~/.bashrc`. Nothing is changed unless you answer `y`.
   - Copies `.envrc.example` to `.envrc` (an existing `.envrc` is left alone), then runs `direnv allow`.

Open a new terminal afterwards so the shell hook takes effect, then `cd` into the repo. You should see `direnv: loading .../.envrc`.

### What gets loaded

The repo-level `.envrc` applies in every folder below it (`my-language/`, `my-language/packages/my-assistant/`, `my-app/`). Everywhere, you get the one `.venv` (LangChain 1.4.6), `poetry install` / `poetry add` install into it, and your keys from `.env` (`OPENAI_API_KEY`, optional `LANGSMITH_*`) are loaded.

### Everyday commands

From the repo root:

```bash
cd my-language && langchain serve           # http://127.0.0.1:8000/assistant/playground/  (Ctrl+C to stop)
cd my-language/packages/my-assistant && pytest   # calls OpenAI once with the Mark Anthony question
cd my-app && pytest                         # the pirate chain
```

### Changing dependencies

All projects share one `.venv`, so keep versions the same everywhere. After any change, run `./run.sh --install`: it installs everything and warns, package by package, if the three lock files disagree.

- **Upgrading the shared LangChain stack:** edit the `# Shared LangChain stack` block the same way in all three `pyproject.toml` files, then re-lock all three from the repo root:
  ```bash
  for d in my-language/packages/my-assistant my-app my-language; do (cd $d && poetry lock --regenerate); done
  ./run.sh --install
  ```
- **my-language** (the LangServe app): `cd my-language && poetry add <package>`
- **my-assistant** (the chain the app serves) installs through `my-language`:
  ```bash
  cd my-language/packages/my-assistant && poetry add --lock <package>   # updates its lock only
  cd ../.. && poetry lock && poetry install                             # back in my-language
  ```
- **my-app**: `cd my-app && poetry add <package>`

If you add a package that more than one project uses, give it the same version constraint in each.

`./run.sh` reinstalls packages by itself whenever `my-language/poetry.lock` changes.

### Keys and `.envrc` stay out of git

`.env` and `.envrc` are in `.gitignore` (in every folder) and must never be committed. Only the templates are tracked: `.env.example` and `.envrc.example`. Neither holds keys. Put keys only in `.env`, never in `.envrc`.

To change direnv settings for yourself, edit your `.envrc` and run `direnv allow` again. direnv blocks a changed `.envrc` until you approve it. To change them for everyone, edit the `.example` template and commit that.

### Without direnv

Do by hand what `.envrc` does, in each new terminal:

```bash
source .venv/bin/activate
set -a; . ./.env; set +a
export PATH="$PWD/.poetry/bin:$PATH" POETRY_VIRTUALENVS_CREATE=false
```

### Troubleshooting

| You see | What to do |
|---|---|
| `direnv: error .envrc is blocked` | Run `direnv allow` in that folder. |
| Nothing loads when you `cd` in | The shell hook is missing. Add `eval "$(direnv hook zsh)"` (or `bash`) to your shell config and open a new terminal. |
| `poetry: command not found` / `no .venv yet` | Run `./run.sh --install`. |
| `OPENAI_API_KEY` not set | Check `.env` exists in the repo root and has the key, then `direnv reload`. |
