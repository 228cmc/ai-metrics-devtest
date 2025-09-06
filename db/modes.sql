# Aggregate facts at daily grain and keep revenue
CREATE OR REPLACE VIEW fact_ads_daily AS
SELECT
  date,
  platform,
  account,
  campaign,
  country,
  device,
  sum(spend) AS spend,
  sum(clicks) AS clicks,
  sum(impressions) AS impressions,
  sum(conversions) AS conversions,
  sum(conversions) * 100.0 AS revenue
FROM ads_spend_raw
GROUP BY 1,2,3,4,5,6;

# KPI view: CAC and ROAS daily at global level
CREATE OR REPLACE VIEW kpi_daily AS
SELECT
  date,
  sum(spend) AS spend,
  sum(conversions) AS conversions,
  sum(conversions) * 100.0 AS revenue,
  CASE WHEN sum(conversions)=0 THEN NULL ELSE sum(spend)/sum(conversions) END AS cac,
  CASE WHEN sum(spend)=0 THEN NULL ELSE (sum(conversions)*100.0)/sum(spend) END AS roas
FROM fact_ads_daily
GROUP BY 1;
