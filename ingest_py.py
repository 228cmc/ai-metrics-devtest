# Ingest data from CSV into DuckDB with enforced schema and upsert
import duckdb
import pandas as pd
from pathlib import Path

DB = "db/ads.duckdb"
CSV = Path("data/ads_spend.csv")

# 1) Read CSV with explicit names and types
# If your CSV already has headers, keep header=0; if not, set header=None
df = pd.read_csv(
    CSV,
    header=0,
    names=["date","platform","account","campaign","country","device","spend","clicks","impressions","conversions"],
    dtype={
        "platform":"string",
        "account":"string",
        "campaign":"string",
        "country":"string",
        "device":"string",
        "spend":"float64",
        "clicks":"Int64",
        "impressions":"Int64",
        "conversions":"Int64",
    },
    parse_dates=["date"],
    dayfirst=False
)

# 2) Normalize types (cast to Python-native for DuckDB)
df["date"] = pd.to_datetime(df["date"]).dt.date
for c in ["clicks","impressions","conversions"]:
    df[c] = df[c].astype("Int64").astype("float").fillna(0).astype(int)

# 3) Upsert into DuckDB
con = duckdb.connect(DB)
con.execute("""
CREATE TABLE IF NOT EXISTS ads_spend_raw (
  date DATE,
  platform VARCHAR,
  account VARCHAR,
  campaign VARCHAR,
  country VARCHAR,
  device VARCHAR,
  spend DOUBLE,
  clicks BIGINT,
  impressions BIGINT,
  conversions BIGINT,
  load_date TIMESTAMP,
  source_file_name VARCHAR
);
""")

# Register pandas DF as a view
con.register("stg_ads", df)

# Delete matching business keys
con.execute("""
DELETE FROM ads_spend_raw
USING stg_ads s
WHERE ads_spend_raw.date = s.date
  AND coalesce(ads_spend_raw.platform,'')  = coalesce(s.platform,'')
  AND coalesce(ads_spend_raw.account,'')   = coalesce(s.account,'')
  AND coalesce(ads_spend_raw.campaign,'')  = coalesce(s.campaign,'')
  AND coalesce(ads_spend_raw.country,'')   = coalesce(s.country,'')
  AND coalesce(ads_spend_raw.device,'')    = coalesce(s.device,'');
""")

# Insert with lineage
con.execute("""
INSERT INTO ads_spend_raw
SELECT
  date::DATE,
  CAST(platform AS VARCHAR),
  CAST(account AS VARCHAR),
  CAST(campaign AS VARCHAR),
  CAST(country AS VARCHAR),
  CAST(device AS VARCHAR),
  CAST(spend AS DOUBLE),
  CAST(clicks AS BIGINT),
  CAST(impressions AS BIGINT),
  CAST(conversions AS BIGINT),
  now() AS load_date,
  'ads_spend.csv' AS source_file_name
FROM stg_ads;
""")

print("Ingest OK")
