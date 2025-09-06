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

   Test it:

   ```bash
   curl "http://localhost:8000/metrics?start=2025-07-01&end=2025-07-30"
   ```

8. Run agent demo

   ```bash
   python agent/demo.py
   ```

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

## Notes

* Provenance tracked with `load_date` and `source_file_name`
* Revenue assumption: `revenue = conversions * 100`
* KPIs:

  * CAC = spend / conversions
  * ROAS = revenue / spend
