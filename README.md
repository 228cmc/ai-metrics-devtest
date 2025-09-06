### `README.md`

```markdown
# AI Metrics DevTest

This repository shows how to build a small but complete pipeline for **ad spend data**:  
- Ingest data automatically with **n8n**  
- Store it in **DuckDB** with lineage metadata  
- Model key metrics like **CAC** and **ROAS** in SQL  
- Expose the results through a simple **FastAPI** service  
- (Bonus) Show how a question in natural language can be mapped to the SQL we built  

The goal is not a production system, but a clear demonstration of approach, SQL modeling, and making metrics accessible.

---

## Tech Choices
- **DuckDB**: lightweight warehouse, easy to run locally and share  
- **n8n**: workflow automation for ingestion and refresh  
- **FastAPI**: quick way to expose KPIs as an endpoint  
- **Makefile**: simple orchestration of common tasks  

---

## Project Layout
```

ai-metrics-devtest/
├─ data/              # raw data files (ads\_spend.csv)
├─ db/                # SQL scripts and DuckDB database
├─ api/               # FastAPI service
├─ agent/             # toy demo for NL → SQL mapping
├─ n8n/               # workflow to orchestrate ingestion
└─ Makefile           # shortcuts to run everything

````

---

## How to Run

1. **Prepare environment**
   ```bash
   make init
   pip install -r requirements.txt
````

2. **Get the dataset**
   Either run the provided n8n workflow (`n8n/workflow.json`) or just:

   ```bash
   curl -L "https://drive.google.com/uc?export=download&id=1RXj_3txgmyX2Wyt9ZwM7l4axfi5A6EC-" -o data/ads_spend.csv
   ```

3. **Ingest and model**

   ```bash
   make ingest
   make models
   ```

4. **Check persistence**

   ```bash
   duckdb db/ads.duckdb -c "SELECT count(*) AS rows, min(date), max(date) FROM ads_spend_raw;"
   ```

5. **Compare last 30 vs prior 30 days**

   ```bash
   make compare
   ```

6. **Run API**

   ```bash
   make api
   ```

   Then test:

   ```bash
   curl "http://localhost:8000/metrics?start=2025-07-01&end=2025-07-30"
   ```

7. **Agent demo (optional)**

   ```bash
   python agent/demo.py
   ```

---

## What to Highlight in the Demo Video

* **Workflow**: n8n downloads the CSV and loads DuckDB
* **Persistence**: data remains in `db/ads.duckdb` after refresh
* **KPIs**: CAC and ROAS, compared across periods
* **API**: easy analyst access with `/metrics?start&end`
* **Bonus**: `agent/demo.py` shows how NL question maps to our SQL

---

## Provenance & Refresh

Every row in the raw table stores:

* `load_date`: when it was ingested
* `source_file_name`: origin file

Refresh is handled by deleting and inserting rows by business key (`date, platform, account, campaign, country, device`).

---

## Why This Setup?

This stack is portable: you can run everything locally without cloud dependencies, but the same ideas translate easily to **BigQuery + dbt + Airflow** in production.
