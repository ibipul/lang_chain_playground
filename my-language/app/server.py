from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from langserve import add_routes

from my_assistant.chain import chain as my_assistant_chain
app = FastAPI()
add_routes(app, my_assistant_chain, path="/assistant")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
