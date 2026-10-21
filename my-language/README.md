# my-language

The web server of this repo. It's a [LangServe](https://github.com/langchain-ai/langserve) app: `app/server.py` creates a FastAPI app and publishes chains on it with `add_routes`. A chain here is what you might call an app: a small Python package whose `chain.py` defines a variable named `chain`. The server can publish as many as you like, each under its own path.

Today it publishes one, [`my-assistant`](packages/my-assistant/README.md), the Mark Anthony role-play assistant:

```python
from my_assistant.chain import chain as my_assistant_chain
from my_assistant.chain import DynamicAssistantInput

add_routes(app, my_assistant_chain, path="/assistant", input_type=DynamicAssistantInput)
```

That one `add_routes` line gives the chain:

| Address | What it is |
|---|---|
| http://localhost:8000/assistant/playground/ | Interactive web interface: fill in the form, read the reply |
| `/assistant/invoke`, `/assistant/stream`, `/assistant/batch` | REST API for `curl` or your own code |
| `/assistant/input_schema`, `/assistant/output_schema` | What the chain expects and returns |
| http://localhost:8000/docs | API docs for every route |

`/` redirects to the assistant's playground.

```
my-language/
├── app/server.py          # the FastAPI app and its add_routes(...) lines
└── packages/              # chains the server publishes
    └── my-assistant/      # one folder per chain
```

The packages aren't installed from here: the repo-root `pyproject.toml` lists every dependency and installs each chain from its folder (see the [main README](../README.md#development)).

**Run it:** `./run.sh` from the repo root, or `cd my-language && langchain serve` with the venv active. `langchain serve` reloads when you save a file in this folder, including anything under `packages/`.

## Add your own chain

A chain is a small Python package with a `chain.py` that defines a variable named `chain`. The quickest start is to copy [`my-app`](../my-app/README.md), the smallest one. Commands below run from the repo root unless they say otherwise, with the venv active (`source .venv/bin/activate`). This example adds `my-poet`, which writes a haiku about a topic, and serves it next to the assistant.

**1. Copy and rename.** Put chains you want served under `my-language/packages/`:

```bash
cp -R my-app my-language/packages/my-poet
mv my-language/packages/my-poet/my_app my-language/packages/my-poet/my_poet
```

In `my-language/packages/my-poet/pyproject.toml`, change `my-app` to `my-poet` and `my_app` to `my_poet` (in `name`, `packages` and `export_module`), and update `description`. In its `tests/test_chain.py`, change the import to `from my_poet.chain import chain`, and give the test an input that matches your chain. Rewrite its `README.md` to describe the new chain.

**2. Write the chain** in `my-language/packages/my-poet/my_poet/chain.py`. Keep the `.env` lines at the top, and end with a variable named `chain`. Declaring the input with `.with_types(...)` gives the playground a proper form:

```python
from dotenv import find_dotenv, load_dotenv

load_dotenv(find_dotenv())

from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field


class PoetInput(BaseModel):
    topic: str = Field(..., description="What the haiku is about.", examples=["autumn rain"])


_prompt = ChatPromptTemplate.from_messages([("system", "Write one haiku about the topic."), ("human", "{topic}")])

chain = (_prompt | ChatOpenAI(model="gpt-3.5-turbo", temperature=0.7) | StrOutputParser()).with_types(input_type=PoetInput)
```

**3. Register it** in the root `pyproject.toml`, from the repo root:

```bash
poetry add --editable ./my-language/packages/my-poet
```

That adds `my-poet = {path = "my-language/packages/my-poet", develop = true}` to the root `pyproject.toml`, updates `poetry.lock` and installs it. If the chain needs a library the repo doesn't have yet, `poetry add <package>` it here too.

**4. Serve it.** In `my-language/app/server.py`, import it and add a route next to the existing one:

```python
from my_poet.chain import chain as my_poet_chain

add_routes(app, my_poet_chain, path="/poet")
```

**5. Try it.** Run `pytest` in `my-language/packages/my-poet`, then `cd my-language && langchain serve` and open http://127.0.0.1:8000/poet/playground/. The assistant stays at `/assistant/playground/`.

For a chain you only want to run, not serve (like `my-app`), skip step 4. It can live in its own top-level folder; then also add a `COPY <folder> ./<folder>` line to the repo-root `Dockerfile`, which copies only `my-language/` and `my-app/`.

### What to update, at a glance

| File | Change |
|---|---|
| `<chain folder>/pyproject.toml` | Package name, `packages` include, `export_module`, description. No dependencies. |
| `<chain folder>/<module>/chain.py` | Your chain, ending in a variable named `chain`. |
| `<chain folder>/tests/test_chain.py` | Import path and test input. |
| `<chain folder>/README.md` | What the chain does (it starts as a copy of `my-app`'s). |
| Root `pyproject.toml` and `poetry.lock` | Done for you by `poetry add --editable ./<chain folder>`; commit both. |
| `my-language/app/server.py` | Import and `add_routes(...)`, only if the chain should be served. |
| Repo-root `Dockerfile` | Only for a new top-level folder: a `COPY` line. |
| `README.md` | Optional: describe the chain under [How the repo fits together](../README.md#how-the-repo-fits-together). |

### Reusing someone else's template

 copy its folder the same way, move its dependencies into the root `pyproject.toml`, and update it to LangChain 1.x (for example, `langchain_core.pydantic_v1` becomes `pydantic`). Don't use `langchain app add`. It downloads from LangChain's old template collection, which was removed from LangChain's main branch and pins LangChain 0.1. It also writes the dependency into the wrong `pyproject.toml` for this layout.
