# agent/demo.py — Answer NL question by computing 30d vs prior 30d directly from kpi_daily
import duckdb
from datetime import timedelta, date

DB = "db/ads.duckdb"

def _compare_30d(con):
    cur = con.execute("SELECT date, spend, conversions, (conversions*100.0) AS revenue FROM kpi_daily ORDER BY date")
    rows = cur.fetchall()
    if not rows:
        return {"error": "kpi_daily is empty. Run: python ingest_py.py, then python run_sql.py"}

    data = [{"date": r[0], "spend": float(r[1] or 0), "conv": float(r[2] or 0), "rev": float(r[3] or 0)} for r in rows]
    min_d = data[0]["date"]
    max_d = data[-1]["date"]

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

    def agg(a: date, b: date):
        spend = conv = rev = 0.0
        for r in data:
            if in_range(r["date"], a, b):
                spend += r["spend"]
                conv  += r["conv"]
                rev   += r["rev"]
        cac  = (spend/conv) if conv > 0 else None
        roas = (rev/spend)  if spend > 0 else None
        return spend, conv, rev, cac, roas

    sl, cl, rl, cacl, roasl = agg(l30_start, l30_end)
    sp, cp, rp, cacp, roasp = agg(p30_start, p30_end)

    def d(a, b):
        if a is None or b is None or b == 0:
            return None
        return (a - b) / abs(b)

    return {
        "ranges": {
            "last_30d":  {"start": str(l30_start), "end": str(l30_end)},
            "prior_30d": {"start": str(p30_start), "end": str(p30_end)}
        },
        "last_30d":  {"CAC": cacl, "ROAS": roasl},
        "prior_30d": {"CAC": cacp, "ROAS": roasp},
        "delta_pct": {"CAC": d(cacl, cacp), "ROAS": d(roasl, roasp)}
    }

def answer(question: str):
    q = question.lower().strip()
    if "compare cac and roas" in q and "last 30" in q:
        con = duckdb.connect(DB, read_only=True)
        return _compare_30d(con)
    return {"info": "no mapping found"}

if __name__ == "__main__":
    print(answer("Compare CAC and ROAS for last 30 days vs prior 30 days."))
