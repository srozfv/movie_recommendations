# backend

This project was scaffolded using the Kunumi Python Styler VS Code extension.

## Run locally
```bash
uvicorn app.main:app --reload
```

## Lint and format
```bash
ruff check . && ruff format .
```

## Docs check (Vale)
```bash
vale .
```

## Pre-commit hooks
```bash
pip install pre-commit
pre-commit install
```
