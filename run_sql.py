# run_sql.py  -> only build models, no CSV read
import duckdb, pathlib

DB = "db/ads.duckdb"

def run_sql_file(path):
    txt = pathlib.Path(path).read_text(encoding="utf-8")
    cleaned = "\n".join(l for l in txt.splitlines() if not l.lstrip().startswith("#"))
    duckdb.connect(DB).execute(cleaned)

print("Building models...")
run_sql_file("db/models.sql")
print("Models OK")
