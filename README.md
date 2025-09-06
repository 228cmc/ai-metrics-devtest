### Quickstart (PowerShell)

1. Clone this repo

```powershell
git clone <your-repo-url>
cd ai-metrics-devtest
```

2. Install requirements

```powershell
pip install -r requirements.txt
```

3. Initialize folders

```powershell
make init
```

*(Si no tienes `make` en Windows, puedes crear las carpetas manualmente:)*

```powershell
mkdir data, db, api, n8n, agent
```

4. Download dataset (manual alternative to n8n)

```powershell
Invoke-WebRequest -Uri "https://drive.google.com/uc?export=download&id=1RXj_3txgmyX2Wyt9ZwM7l4axfi5A6EC-" -OutFile "data/ads_spend.csv"
```

5. Ingest and build models

```powershell
duckdb db/ads.duckdb ".read db/ingest.sql"
duckdb db/ads.duckdb ".read db/models.sql"
```

6. Compare KPIs (last 30d vs prior 30d)

```powershell
duckdb db/ads.duckdb ".read db/kpi_compare_30d.sql"
```

7. Run API

```powershell
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Test endpoint:

```powershell
Invoke-RestMethod "http://localhost:8000/metrics?start=2025-07-01&end=2025-07-30"
```

8. Run agent demo

```powershell
python agent/demo.py
```

