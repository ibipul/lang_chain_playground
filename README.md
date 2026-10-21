# Hands-on  langchain

[![Python 3.11+](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![LangChain 1.1.0](https://img.shields.io/badge/LangChain-1.1.0-1C3C3C?logo=langchain&logoColor=white)](https://python.langchain.com/)
[![LangServe 0.3.3](https://img.shields.io/badge/LangServe-0.3.3-1C3C3C?logo=langchain&logoColor=white)](https://github.com/langchain-ai/langserve)
[![LangSmith 0.4.50](https://img.shields.io/badge/LangSmith-0.4.50-1C3C3C?logo=langchain&logoColor=white)](https://smith.langchain.com/)
[![OpenAI GPT-3.5 Turbo](https://img.shields.io/badge/OpenAI-GPT--3.5%20Turbo%20%2B%20Embeddings-412991)](https://platform.openai.com/docs/models)
[![FAISS](https://img.shields.io/badge/FAISS-vector%20store-0467DF?logo=meta&logoColor=white)](https://github.com/facebookresearch/faiss)
[![FastAPI 0.123.4](https://img.shields.io/badge/FastAPI-0.123.4-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Uvicorn 0.23.2](https://img.shields.io/badge/Uvicorn-0.23.2-499848?logo=gunicorn&logoColor=white)](https://www.uvicorn.org/)
[![Pydantic 2.12.5](https://img.shields.io/badge/Pydantic-2.12.5-E92063?logo=pydantic&logoColor=white)](https://docs.pydantic.dev/)
[![Poetry](https://img.shields.io/badge/Poetry-dependency%20management-60A5FA?logo=poetry&logoColor=white)](https://python-poetry.org/)
[![Docker](https://img.shields.io/badge/Docker-python%3A3.11--slim-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

Requirements:
```
python = ">=3.10,<4.0"
langchain-core = "^1.0.0" 
langchain = "^1.0.0"
langchain-openai = "^1.1.0" 
langserve = "^0.3.0"
langsmith = "^0.4.0" 
langchain-community = "^0.4.1"
```

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


### Develop with a virtual environment
 - Switch into top-level directory
 - python3 -m venv .venv (create a venv)
 - add export PIP_INDEX_URL=https://pypi.org/simple/ to the end of .venv/bin/activate
 - add export PIP_EXTRA_INDEX_URL="" to the end of .venv/bin/activate
 - activate venv: source .venv/bin/activate
 - Then switch to `my-app` directory and do `poetry install`
 - Similarly switch to `my-language` directory and do a `poetry install`

### Packages to have in venv
 - homebrew install envdir
 - You can use envdir to load secrects like API_KEYS in .envrc
 - add `.venv`, `.envrc` in `.gitignore` to ensure not uploading your open AI keys to public
 - pip install requests
 - you will need poetry

### Installation & troubleshooting
 - Create your virtual env inside the main cloned directory activate it
 - update your langchan/langsmith API_KEYS in .envrc (with apt gitignore)
   - you need to set `direnv allow` when the system prompts you.
 - navigate to `my-language/packages/my-assistant`
   - Do a `poetry lock`, `poetry install`
 - Navigate back out to `../..` to `my-language`
   - do another `poetry lock`, and then `poetry install`
 - From `/my-language` launch with `langchain serve`
   - If you might face random errors at `langchain serve` start
   - `pip install --upgrade typer click`, apparently this is because of some issue with typer.
  
Pretty straight forward python dependency debugging

 
