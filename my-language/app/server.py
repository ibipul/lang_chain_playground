from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from langserve import add_routes

# 1. my chain
from my_assistant.chain import chain as my_assistant_chain
# 2. Input schema
from my_assistant.chain import DynamicAssistantInput

app = FastAPI(
    title="Mark Anthony Assistant Service",
    version="0.1.0",
    description="A Shakespearean assistant that answers questions in the style of Mark Anthony."
)
@app.get("/")
async def redirect_root_to_playground():
    return RedirectResponse("/assistant/playground")

add_routes(app, my_assistant_chain, path="/assistant",input_type=DynamicAssistantInput)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
