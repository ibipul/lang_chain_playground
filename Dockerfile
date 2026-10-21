# Image for the my-language LangServe app. Build from the repo root:
#   docker build -t lang-chain-playground .
#   docker run --env-file .env -p 8080:8080 lang-chain-playground
# then open http://localhost:8080/assistant/playground/
FROM python:3.11-slim

RUN pip install poetry==2.2.1
RUN poetry config virtualenvs.create false

WORKDIR /code

# One pyproject.toml + poetry.lock at the root; the local chains install from their folders.
COPY pyproject.toml poetry.lock ./
COPY my-language ./my-language
COPY my-app ./my-app
RUN poetry install --only main --no-interaction --no-ansi

WORKDIR /code/my-language
EXPOSE 8080
CMD exec uvicorn app.server:app --host 0.0.0.0 --port 8080
