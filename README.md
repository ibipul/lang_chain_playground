# Hands-on  langchain

For this project I created a virtual environment in the root directory, and did everything inside it.

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
 - navigate to `my-language/packages/my-assistant`
   - Do a `poetry lock`, `poetry install`
 - Navigate back out to `../..` to `my-language`
   - do another `poetry lock`, and then `poetry install`
 - update your langchan/langsmith API_KEYS in .envrc (with apt gitignore)
 - you need to set `direnv allow` when the system prompts you.
 - From `/my-language` launch with `langchain serve`

 
