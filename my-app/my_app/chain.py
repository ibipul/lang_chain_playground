from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from langchain_core.pydantic_v1 import BaseModel, Field

# --- Define the Pydantic Input Schema ---
# The field name 'text' MUST match the variable name in your prompt template: {text}
class PirateInput(BaseModel):
    """Input schema for the Pirate Assistant chain."""
    text: str = Field(
        ...,
        description="The message to be translated into pirate speech.",
        examples=["Hello, how are you today, friend?"],
    )

_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are a helpful assistant who speaks like a pirate. Keep your response brief.",
        ),
        ("human", "{text}"),
    ]
)
_model = ChatOpenAI(temperature=0.7)

# if you update this, you MUST also update ../pyproject.toml
# with the new `tool.langserve.export_attr`

# The chain MUST be explicitly typed using .with_types(input_type=...)
# This tells LangServe/FastAPI exactly what JSON schema to expect in the request body,
# resolving the "AssertionError" because the input parameter is now clearly defined.
# CRITICAL: The chain MUST use .with_types(input_type=...)
chain = (_prompt | _model).with_types(input_type=PirateInput)