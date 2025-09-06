# Here we create a daily fact view aggregating spend, clicks, impressions, conversions, and revenue
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

# Here we create a KPI view that calculates CAC and ROAS by day
# KPIs explained:
# CAC (Customer Acquisition Cost):
#   Measures how much money is spent to acquire one customer.
#   Formula: total spend ÷ number of conversions.
#   Lower CAC means more efficient campaigns (cheaper cost per acquisition).
# ROAS (Return On Ad Spend):
#   Measures the revenue generated for each unit of money spent on ads.
#   Formula: revenue ÷ spend.
#   In this dataset, revenue is defined as conversions × 100.
#   Higher ROAS means better returns from advertising investment.


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
