from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from langchain_openai.embeddings import OpenAIEmbeddings # <-- for knowledge embeddings
#from langchain_openai.moderation import OpenAIModerationChain #<-- for moderation
#from langchain.chains.openai_moderation import OpenAIModerationChain

from langchain_community.vectorstores import FAISS

from pydantic import BaseModel, Field
from operator import itemgetter
from typing import Dict, Union, List

#moderation hack
from langchain_core.runnables import RunnableLambda, RunnableBranch, RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

# Define the Pydantic Input Schema to accept all configuration fields
class DynamicAssistantInput(BaseModel):
    """Input schema for the dynamic role-playing chain."""
    question: str = Field(
        ...,
        description="The message or question for the role-playing character.",
        examples=["What news of the world doth trouble thy sleep?"],
    )
    character: str = Field(
        "Mark Anthony",
        description="The name of the character to role-play as (e.g., 'Hamlet').",
    )
    title: str = Field(
        "Julius Caesar",
        description="The title of the work the character is from (e.g., 'Hamlet').",
    )
    personality: str = Field(
        "sullen mood, rhetorical, sarcastic, and dramatic",
        description="The personality or mood of the character.",
    )


def keyword_filter(input_dict: dict) -> Union[dict, None]:
    """Checks the input question for blacklisted keywords."""
    question = input_dict['question'].lower()
    if any(word in question for word in {"fuck", "shit","bullshit","bastard"}):
        # Return None to signal a block
        return None 
    # If safe, return the original dictionary to continue the pipeline
    return input_dict 

_keyword_check = RunnableLambda(keyword_filter).with_types(input_type=DynamicAssistantInput, output_type=Union[dict, None])
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

# 4. Helper function to format retrieved documents
def format_docs(docs: List) -> str:
    """Formats a list of Document objects into a clean, single string."""
    return "\n\n".join(doc.page_content for doc in docs)


# --- Core Role-Play Prompt ---
_roleplay_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are role playing as {character} the character from {title}. \
            When the user asks questions be sure to always respond in character at all times.\
            You speak in archaic English style like Shakespeare write.\
            {character} has a {personality}. \
            When asked a question, additionally use the following context to inform your answer: {context}\
            Dont foget to stay in character!",
        ),
        ("human", "{question}"),
    ]
)
_model = ChatOpenAI(temperature=0.5, model="gpt-3.5-turbo")

# --- Sentiment Analysis Chain Setup ---
_sentiment_prompt = ChatPromptTemplate.from_template(
    "Analyze the tone and emotion of the following text and classify its sentiment.\
     Respond ONLY with a single adjective that describes the emotional state of the character \
     (e.g., 'Cynical', 'Melancholy', 'Excited').\n\nTEXT: {response}"
)
# Use a low temperature for consistent classification
_sentiment_model = ChatOpenAI(temperature=0.0, model="gpt-3.5-turbo")

_sentiment_chain = (
    # The input key for the prompt is 'response'
    {"response": itemgetter("response")} 
    | _sentiment_prompt 
    | _sentiment_model
    | StrOutputParser()
)
# --- End Sentiment Chain Setup ---


# 1. Sub-chain to handle RAG and all initial context/parameters
_initial_context = RunnablePassthrough.assign(
    context = itemgetter("question") | retriever | format_docs,
    question=itemgetter("question"),
    character=itemgetter("character"),
    title=itemgetter("title"),
    personality=itemgetter("personality"),
)

# 2. Sub-chain for Role-Play Generation (produces a BaseMessage)
_roleplay_generator = _roleplay_prompt | _model


# The dynamic LCEL chain (the full execution path if moderation passes)
# The key change is using _initial_context and explicitly assigning the full 
# generated response (after parsing) into the 'response' key.
_chain = (
    # Step 1: Set up the full dictionary context (RAG, character info)
    _initial_context
    
    # Step 2: Run the Role-Play Generator and parse its output. 
    # This step is critical: using it inside RunnablePassthrough.assign() forces 
    # the entire stream to be collected and converted to a string before assigning it to 'response'.
    | RunnablePassthrough.assign(
        response=_roleplay_generator | StrOutputParser()
    )
    
    # Step 3: Run the Sentiment Chain using the now-collected 'response' key from the dictionary
    | RunnablePassthrough.assign(
        sentiment=_sentiment_chain,
    )
    
    # Step 4: Final Formatting
    | (lambda x: f"{x['response']}\n\n[Mood: {x['sentiment'].strip().capitalize()}]")

).with_types(input_type=DynamicAssistantInput)

# The final top-level runnable (including moderation branching)
chain =(
    _keyword_check | RunnableBranch(
        # Condition 1 (True): If the input is None (meaning blocked)
        (lambda x: x is None, _blocked_response), 
        # Condition 2 (Default): Otherwise, run the full execution chain
        _chain
    )
)