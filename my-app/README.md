# my-app

The first demo in this repo: a chain that answers like a pirate. It's as small as a LangChain chain gets, one prompt and one chat model, with a declared input so tools know what it expects.

It's where [`my-assistant`](../my-language/packages/my-assistant/README.md) came from. The same idea, a system prompt that gives the model a character, grew into the Mark Anthony role-play assistant: any character from any book or play, a personality cue, an Orwell knowledge base for context, a word filter and a mood tag, served on the web by `my-language`.

```
my-app/
├── my_app/chain.py        # the chain: prompt | ChatOpenAI, input {"text": "..."}
├── tests/test_chain.py    # calls the chain once with a greeting
└── pyproject.toml         # package name only; dependencies live in the repo-root pyproject.toml
```

It's installed into the repo's `.venv` with everything else. Nothing serves it; run it through its test, with the venv active:

```bash
cd my-app && pytest -s     # -s prints the pirate's reply
```

**Use it as a template.** Because it's so small, copying this folder is the quickest way to start a new chain. The step-by-step guide is in [my-language/README.md](../my-language/README.md#add-your-own-chain).
