# my-assistant

The Mark Anthony role-play chain (`my_assistant/chain.py`) that `my-language` serves at `/assistant`: a word filter, a FAISS lookup over `orwell_facts.txt`, an in-character answer and a mood tag.

Its `pyproject.toml` lists the libraries it imports (including FAISS); the repo-root `pyproject.toml` installs it, and the root `poetry.lock` picks the versions. See [Dependencies](../../../README.md#dependencies) in the main README. Test it with `pytest` from this folder with the venv active.
