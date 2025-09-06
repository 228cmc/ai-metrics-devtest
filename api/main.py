# FastAPI service exposing metrics
from fastapi import FastAPI, HTTPException, Query
import duckdb

app = FastAPI(title="Metrics API", version="1.0")
DB_PATH = "db/ads.duckdb"

# Query template with parameters
Q = """
WITH rng AS (SELECT ?::DATE AS start_d, ?::DATE AS end_d)
SELECT
  sum(spend) AS spend,
  sum(conversions) AS conversions,
  sum(conversions)*100.0 AS revenue,
  CASE WHEN sum(conversions)=0 THEN NULL ELSE sum(spend)/sum(conversions) END AS cac,
  CASE WHEN sum(spend)=0 THEN NULL ELSE (sum(conversions)*100.0)/sum(spend) END AS roas
FROM kpi_daily, rng
WHERE date BETWEEN rng.start_d AND rng.end_d;
"""

@app.get("/metrics")
def metrics(start: str = Query(...), end: str = Query(...)):
    # Connect to DuckDB and execute query
    try:
        with duckdb.connect(DB_PATH, read_only=True) as con:
            row = con.execute(Q, [start, end]).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="No data")
            spend, conversions, revenue, cac, roas = row
            return {
                "start": start,
                "end": end,
                "spend": float(spend or 0),
                "conversions": int(conversions or 0),
                "revenue": float(revenue or 0),
                "cac": None if cac is None else float(cac),
                "roas": None if roas is None else float(roas)
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
