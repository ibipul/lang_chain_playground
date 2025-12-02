from my_app.chain import chain 

def test_chain():
    print(
        chain.invoke({"text": "hello there, do you have any gold for me?"})
    )
