# Here we get the latest available date in the dataset
WITH bounds AS (
  SELECT max(date) AS max_d FROM kpi_daily
),

# Here we define the ranges for last 30 days and prior 30 days
ranges AS (
  SELECT
    date_trunc('day', max_d) AS ref_day,
    (date_trunc('day', max_d) - INTERVAL 29 DAY) AS l30_start,
    (date_trunc('day', max_d)) AS l30_end,
    (date_trunc('day', max_d) - INTERVAL 59 DAY) AS p30_start,
    (date_trunc('day', max_d) - INTERVAL 30 DAY) AS p30_end
  FROM bounds
),

# Here we aggregate totals for each period
agg AS (
  SELECT
    'last_30d' AS period,
    sum(spend) AS spend,
    sum(conversions) AS conversions,
    sum(revenue) AS revenue
  FROM kpi_daily, ranges
  WHERE date BETWEEN ranges.l30_start AND ranges.l30_end
  UNION ALL
  SELECT
    'prior_30d',
    sum(spend),
    sum(conversions),
    sum(revenue)
  FROM kpi_daily, ranges
  WHERE date BETWEEN ranges.p30_start AND ranges.p30_end
),

# Here we calculate CAC and ROAS for each period
kpi AS (
  SELECT
    period,
    spend,
    conversions,
    revenue,
    CASE WHEN conversions=0 THEN NULL ELSE spend/conversions END AS cac,
    CASE WHEN spend=0 THEN NULL ELSE revenue/spend END AS roas
  FROM agg
),

# Here we pivot results to compare periods side by side
pivot AS (
  SELECT
    max(CASE WHEN period='last_30d'  THEN cac END)  AS cac_l30,
    max(CASE WHEN period='prior_30d' THEN cac END)  AS cac_p30,
    max(CASE WHEN period='last_30d'  THEN roas END) AS roas_l30,
    max(CASE WHEN period='prior_30d' THEN roas END) AS roas_p30,
    max(CASE WHEN period='last_30d'  THEN spend END) AS spend_l30,
    max(CASE WHEN period='prior_30d' THEN spend END) AS spend_p30,
    max(CASE WHEN period='last_30d'  THEN conversions END) AS conv_l30,
    max(CASE WHEN period='prior_30d' THEN conversions END) AS conv_p30,
    max(CASE WHEN period='last_30d'  THEN revenue END) AS rev_l30,
    max(CASE WHEN period='prior_30d' THEN revenue END) AS rev_p30
  FROM kpi
)

# Here we return the final comparison with percentage deltas
SELECT
  spend_l30, spend_p30,
  conv_l30, conv_p30,
  rev_l30,  rev_p30,
  cac_l30,  cac_p30,
  roas_l30, roas_p30,
  (cac_l30 - cac_p30) / NULLIF(abs(cac_p30),0) AS cac_delta_pct,
  (roas_l30 - roas_p30) / NULLIF(abs(roas_p30),0) AS roas_delta_pct
FROM pivot;
