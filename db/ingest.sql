# Create raw table if not exists
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

# Parallelism
PRAGMA threads=4;

# Staging view: force column names, then cast types explicitly
CREATE OR REPLACE TEMP VIEW _stg_ads AS
SELECT
  CAST(date        AS DATE)    AS date,
  CAST(platform    AS VARCHAR) AS platform,
  CAST(account     AS VARCHAR) AS account,
  CAST(campaign    AS VARCHAR) AS campaign,
  CAST(country     AS VARCHAR) AS country,
  CAST(device      AS VARCHAR) AS device,
  CAST(spend       AS DOUBLE)  AS spend,
  CAST(clicks      AS BIGINT)  AS clicks,
  CAST(impressions AS BIGINT)  AS impressions,
  CAST(conversions AS BIGINT)  AS conversions
FROM read_csv_auto(
  'data/ads_spend.csv',
  header := true,
  column_names := ['date','platform','account','campaign','country','device','spend','clicks','impressions','conversions'],
  dateformat := '%Y-%m-%d',
  sample_size := -1
);

# Upsert: delete matching business keys, then insert fresh rows with lineage
DELETE FROM ads_spend_raw
USING _stg_ads s
WHERE ads_spend_raw.date = s.date
  AND coalesce(ads_spend_raw.platform,'')  = coalesce(s.platform,'')
  AND coalesce(ads_spend_raw.account,'')   = coalesce(s.account,'')
  AND coalesce(ads_spend_raw.campaign,'')  = coalesce(s.campaign,'')
  AND coalesce(ads_spend_raw.country,'')   = coalesce(s.country,'')
  AND coalesce(ads_spend_raw.device,'')    = coalesce(s.device,'');

INSERT INTO ads_spend_raw
SELECT
  date, platform, account, campaign, country, device,
  spend, clicks, impressions, conversions,
  now() AS load_date,
  'ads_spend.csv' AS source_file_name
FROM _stg_ads;
