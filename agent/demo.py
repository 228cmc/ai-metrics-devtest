# Demo script: natural language mapping to SQL for KPI comparison
import duckdb

def answer(question: str):
    q = question.lower()
    if "compare cac and roas" in q and "last 30" in q:
        # Load prebuilt SQL file for 30-day comparison
        sql = open("db/kpi_compare_30d.sql").read()
        with duckdb.connect("db/ads.duckdb", read_only=True) as con:
            row = con.execute(sql).fetchone()
            if not row:
                return {"error": "no data"}
            (spend_l30, spend_p30, conv_l30, conv_p30, rev_l30, rev_p30,
             cac_l30, cac_p30, roas_l30, roas_p30,
             cac_delta_pct, roas_delta_pct) = row
            return {
                "last_30d": {
                    "CAC": None if cac_l30 is None else float(cac_l30),
                    "ROAS": None if roas_l30 is None else float(roas_l30)
                },
                "prior_30d": {
                    "CAC": None if cac_p30 is None else float(cac_p30),
                    "ROAS": None if roas_p30 is None else float(roas_p30)
                },
                "delta_pct": {
                    "CAC": None if cac_delta_pct is None else float(cac_delta_pct),
                    "ROAS": None if roas_delta_pct is None else float(roas_delta_pct)
                }
            }
    return {"info": "no mapping found"}

if __name__ == "__main__":
    print(answer("Compare CAC and ROAS for last 30 days vs prior 30 days."))
