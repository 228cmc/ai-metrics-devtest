# Here we create the raw table if it does not exist yet
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

# Allow multiple threads for ingestion
PRAGMA threads=4;

# Here we create a temporary view reading the CSV
CREATE OR REPLACE TEMP VIEW _stg_ads AS
SELECT
  try_cast(date AS DATE) AS date,
  platform::VARCHAR,
  account::VARCHAR,
  campaign::VARCHAR,
  country::VARCHAR,
  device::VARCHAR,
  try_cast(spend AS DOUBLE) AS spend,
  try_cast(clicks AS BIGINT) AS clicks,
  try_cast(impressions AS BIGINT) AS impressions,
  try_cast(conversions AS BIGINT) AS conversions
FROM read_csv_auto('data/ads_spend.csv', header=true, dateformat='%Y-%m-%d');

# Here we delete duplicates using business keys before inserting
DELETE FROM ads_spend_raw
USING _stg_ads s
WHERE ads_spend_raw.date = s.date
  AND coalesce(ads_spend_raw.platform,'')  = coalesce(s.platform,'')
  AND coalesce(ads_spend_raw.account,'')   = coalesce(s.account,'')
  AND coalesce(ads_spend_raw.campaign,'')  = coalesce(s.campaign,'')
  AND coalesce(ads_spend_raw.country,'')   = coalesce(s.country,'')
  AND coalesce(ads_spend_raw.device,'')    = coalesce(s.device,'');

# Here we insert new rows and add lineage fields
INSERT INTO ads_spend_raw
SELECT
  date, platform, account, campaign, country, device,
  spend, clicks, impressions, conversions,
  now() AS load_date,
  'ads_spend.csv' AS source_file_name
FROM _stg_ads;
