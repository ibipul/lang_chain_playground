import langsmith
from my_assistant.chain import chain 

from datetime import datetime

def test_chain_basic():
    # -- basic invocation of chain --#
    input_data = {"text": "Hello, how are you today, friend?"}
    result = chain.invoke(input_data)
    print(result)

def test_chain_langsmith():
    # -- chain invocation wrapped with langsmith client --#
    client = langsmith.Client()
    date_int = int(datetime.now().timestamp())
    chain_result = client.run_on_dataset(
        dataset_name="pirate-dataset-echo-chain",
        llm_or_chain_factory=chain,
        project_name=f"pirate-dataset-echo-chain-test-{date_int}",
        concurrency_level=2,
        verbose=True
    )
        
    
