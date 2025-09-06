### `README.md`

````markdown
# AI Data Engineer DevTest

This repo shows a simple pipeline for ingesting ad spend data, modeling KPIs, and exposing them to analysts.

## How it works
- **n8n workflow** downloads the CSV daily from Google Drive and loads it into DuckDB.
- **SQL models** calculate CAC and ROAS, and compare last 30 days vs the prior 30 days.
- **FastAPI** exposes an endpoint `/metrics?start&end` to fetch KPIs as JSON.
- **Agent demo** maps a natural language question to the SQL comparison query.

## Quickstart

1. Clone this repo  
   ```bash
   git clone <your-repo-url>
   cd ai-metrics-devtest
````

2. Install requirements

   ```bash
   pip install -r requirements.txt
   ```

3. Initialize folders

   ```bash
   make init
   ```

4. Download dataset (manual alternative to n8n)

   ```bash
   curl -L "https://drive.google.com/uc?export=download&id=1RXj_3txgmyX2Wyt9ZwM7l4axfi5A6EC-" -o data/ads_spend.csv
   ```

5. Ingest and build models

   ```bash
   make ingest
   make models
   ```

6. Compare KPIs (last 30d vs prior 30d)

   ```bash
   make compare
   ```

7. Run API

   ```bash
   make api
   ```

   Test endpoint:

   ```bash
   curl "http://localhost:8000/metrics?start=2025-07-01&end=2025-07-30"
   ```

8. Run agent demo

   ```bash
   python agent/demo.py
   ```

---

## Repo structure

```
ai-metrics-devtest/
├─ data/              # raw dataset
├─ db/                # DuckDB database and SQL models
├─ api/               # FastAPI endpoint
├─ agent/             # NL → SQL demo
├─ n8n/               # workflow for ingestion
└─ Makefile           # helper commands
```

---

## What each part is (simple)

* **DuckDB**: a small database stored in one file. Like SQLite, but made for analytics.
* **n8n**: a workflow automation tool. It runs steps every day: download → save → run SQL.
* **CSV**: plain text file with ad spend data (spend, clicks, conversions, etc.).
* **SQL**: the language to clean, transform, and calculate metrics in the database.
* **CAC**: Customer Acquisition Cost = spend ÷ conversions.
* **ROAS**: Return on Ad Spend = revenue ÷ spend (here revenue = conversions × 100).
* **FastAPI**: a Python library to expose results as an API endpoint.
* **Agent demo**: a small script that takes a natural language question and runs the right SQL query.
* **Makefile**: shortcuts to run commands easily (e.g. `make ingest`, `make api`).

---

## Summary

* **n8n** automates ingestion daily.
* **DuckDB + SQL** store data and calculate KPIs.
* **FastAPI** makes metrics accessible in JSON.
* **Agent demo** shows how to answer questions in natural language.

```

