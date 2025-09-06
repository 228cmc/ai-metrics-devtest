# compare.py: comparación 30d evitando pandas por completo
import duckdb
from datetime import timedelta, date

con = duckdb.connect("db/ads.duckdb")

# traiga todo kpi_daily en memoria (poca data)
cur = con.execute("SELECT date, spend, conversions, (conversions*100.0) AS revenue FROM kpi_daily ORDER BY date")
cols = [c[0] for c in cur.description]
rows = cur.fetchall()

if not rows:
    raise SystemExit("kpi_daily vacío. Ejecute: python ingest_py.py y luego python run_sql.py")

# convierta a estructuras nativas
data = [{"date": r[0], "spend": float(r[1] or 0), "conversions": float(r[2] or 0), "revenue": float(r[3] or 0)} for r in rows]
min_d = data[0]["date"]
max_d = data[-1]["date"]

# ventanas
l30_start = max_d - timedelta(days=29)
if l30_start < min_d:
    l30_start = min_d
l30_end = max_d

p30_end = l30_start - timedelta(days=1)
p30_start = p30_end - timedelta(days=29)
if p30_start < min_d:
    p30_start = min_d

def in_range(d: date, a: date, b: date) -> bool:
    return a <= d <= b

def agg(a, b):
    spend = conv = rev = 0.0
    for r in data:
        if in_range(r["date"], a, b):
            spend += r["spend"]
            conv  += r["conversions"]
            rev   += r["revenue"]
    cac  = (spend/conv) if conv > 0 else None
    roas = (rev/spend)  if spend > 0 else None
    return spend, conv, rev, cac, roas

spend_l30, conv_l30, rev_l30, cac_l30, roas_l30 = agg(l30_start, l30_end)
spend_p30, conv_p30, rev_p30, cac_p30, roas_p30 = agg(p30_start, p30_end)

def delta_pct(a, b):
    if a is None or b is None or b == 0:
        return None
    return (a - b) / abs(b)

print("KPI comparison: last 30 days vs prior 30 days")
print(f"last_30d:  {l30_start} → {l30_end}")
print(f"prior_30d: {p30_start} → {p30_end}")
print("")
print("spend_l30:", spend_l30, "  spend_p30:", spend_p30)
print("conv_l30: ", conv_l30,  "  conv_p30: ", conv_p30)
print("rev_l30:  ", rev_l30,   "  rev_p30:  ", rev_p30)
print("cac_l30:  ", None if cac_l30 is None else round(cac_l30, 6),
      "  cac_p30:  ", None if cac_p30 is None else round(cac_p30, 6),
      "  cac_delta_pct:", None if delta_pct(cac_l30, cac_p30) is None else round(delta_pct(cac_l30, cac_p30), 6))
print("roas_l30: ", None if roas_l30 is None else round(roas_l30, 6),
      "  roas_p30: ", None if roas_p30 is None else round(roas_p30, 6),
      "  roas_delta_pct:", None if delta_pct(roas_l30, roas_p30) is None else round(delta_pct(roas_l30, roas_p30), 6))
