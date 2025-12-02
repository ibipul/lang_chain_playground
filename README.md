# Hands-on  langchain

For this project I created a virtual environment in the root directory, and did everything inside it.

### my-app
A simple prompt|model response chain
 - `langchain template new my-app` 
 - needs OpenAI api key (get your own)
 - ensure poetry dependencies are resolved

### my-language
Setup a REST API with langchain serve
 - `langchain app new my-language --package $PWD/my-app` 
 - `add_routes(app, my_app_chain, path="/my-app")`
 -  ensure poetry dependencied are resolved
 -  `cd my-language; langchain serve`
 - `http://127.0.0.1:8000/docs` to see all the API endpoints
 - `http://127.0.0.1:8000/my-app/playground` to get a default chat interface

