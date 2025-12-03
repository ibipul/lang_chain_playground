# Hands-on  langchain

For this project I created a virtual environment in the root directory, and did everything inside it.

### my-app
A simple prompt|model response chain
 - `langchain template new my-app` 
 - needs OpenAI api key (get your own)
 - ensure poetry dependencies are resolved

### my-language
Setup a REST API with langchain serve. It serves a RAG bases assistant, which speaks like Mark Anthony in rhetorics and shakespearean tongues, and has an context of George Orwell, it is designed to say pessimistic stuff.
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
        "text": "Tell me a short, funny fact about the moon."
    }
}'
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

 