from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from langchain_openai.embeddings import OpenAIEmbeddings # <-- for knowledge embeddings
#from langchain_openai.moderation import OpenAIModerationChain #<-- for moderation
#from langchain.chains.openai_moderation import OpenAIModerationChain

from langchain_community.vectorstores import FAISS

from pydantic import BaseModel, Field
from operator import itemgetter
from typing import Dict, Union

#moderation hack
from langchain_core.runnables import RunnableLambda, RunnableBranch, RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

# Define the Pydantic Input Schema:The field name 'text' MUST match the variable name in your prompt template: {text}
class StrInput(BaseModel):
    """Input schema for the Mark Anthony a Shakespearean Assistant chain."""
    question: str = Field(
        ...,
        description="The message to be translated into Mark Anthony's speech.",
        examples=["Hello, how are you today, friend?"],
    )


def keyword_filter(input_dict: dict) -> Union[dict, None]:
    """Checks the input question for blacklisted keywords."""
    question = input_dict['question'].lower()
    if any(word in question for word in {"fuck", "shit","bullshit","bastard"}):
        # Return None to signal a block
        return None 
    # If safe, return the original dictionary to continue the pipeline
    return input_dict 

_keyword_check = RunnableLambda(keyword_filter).with_types(input_type=StrInput, output_type=Union[dict, None])
# The clean response to send if the input is blocked
_blocked_response = RunnableLambda(
    lambda x: "Hark! Such foul language doth offend the ears of Mark Anthony. I shall not respond to such vulgarity. Speak cleanly, friend."
)

import pathlib
THIS_DIR = pathlib.Path(__file__).parent
CONTEXT_FILE_PATH = THIS_DIR / "orwell_facts.txt"

# 1. Load some knowledge data about George Orwell from a text file
try:
    george_orwell_info = []
    with open(CONTEXT_FILE_PATH, 'r', encoding='utf-8') as file: # Load knowledge data from a text file
        for line in file:
            cleaned_line = line.strip()
            if cleaned_line: #ignoring empty lines
                george_orwell_info.append(cleaned_line)
except FileNotFoundError:
    george_orwell_info = ["George Orwell was an English novelist, essayist, journalist and critic."]

# 2. Embed the knowledge data into a vector store
vectorstore = FAISS.from_texts(
    george_orwell_info,
    embedding=OpenAIEmbeddings(),
)

# 3. Retriver object to fetch relevant knowledge
retriever = vectorstore.as_retriever()




_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are a Mark Anthony the character created by Shakespeare. \
            You speak in archaic English style like Shakespeare write.\
            You have a sullen mood, and you way of speaking is rhetorical, sarcastic and dramatic. \
            When asked a question, use the following to respond: {context}",
        ),
        ("human", "{question}"),
    ]
)
_model = ChatOpenAI(temperature=0.5)
#_moderation_chain = OpenAIModerationChain()

# if you update this name, you MUST also update ../pyproject.toml
# with the new `tool.langserve.export_attr`
# {
#     # 1. CONTEXT: Extracts the 'question' string and passes it to the retriever. Output is named 'context'.
#     "context": itemgetter("question") | retriever,
#     # 2. QUESTION: Extracts the 'question' string and passes it to the prompt.
#     "question": itemgetter("question")
# }

_chain = RunnablePassthrough.assign(
                context = itemgetter("question") | retriever   
        )| _prompt | _model| StrOutputParser()

chain =(
    _keyword_check | RunnableBranch(
        # Condition 1 (True): If the input is None (meaning blocked)
        (lambda x: x is None, _blocked_response), 
        # Condition 2 (Default): Otherwise, run the RAG chain
        _chain
    )
)