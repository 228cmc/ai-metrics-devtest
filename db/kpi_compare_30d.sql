# Robust 30d vs prior 30d using only available data and scalar subqueries
WITH bounds AS (
  SELECT
    min(date) AS min_d,
    max(date) AS max_d
  FROM kpi_daily
),
ranges AS (
  SELECT
    max_d,
    min_d,
    GREATEST(max_d - INTERVAL 29 DAY, min_d) AS l30_start,
    max_d                                   AS l30_end,
    GREATEST((GREATEST(max_d - INTERVAL 29 DAY, min_d) - INTERVAL 30 DAY), min_d) AS p30_start,
    (GREATEST(max_d - INTERVAL 29 DAY, min_d) - INTERVAL 1 DAY)                    AS p30_end
  FROM bounds
)
SELECT
  /* last 30d aggregates */
  (SELECT COALESCE(SUM(spend),0)       FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end) AS spend_l30,
  (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end) AS conv_l30,
  (SELECT COALESCE(SUM(revenue),0)     FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end) AS rev_l30,

  /* prior 30d aggregates */
  (SELECT COALESCE(SUM(spend),0)       FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end) AS spend_p30,
  (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end) AS conv_p30,
  (SELECT COALESCE(SUM(revenue),0)     FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end) AS rev_p30,

  /* KPIs last 30d */
  CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)=0
       THEN NULL
       ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
          / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
  END AS cac_l30,
  CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)=0
       THEN NULL
       ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
          / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
  END AS roas_l30,

  /* KPIs prior 30d */
  CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
       THEN NULL
       ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
          / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
  END AS cac_p30,
  CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
       THEN NULL
       ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
          / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
  END AS roas_p30,

  /* deltas */
  CASE
    WHEN (
      CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
           THEN NULL
           ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
              / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
      END
    ) IS NULL
    THEN NULL
    ELSE (
      (CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)=0
            THEN NULL
            ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
               / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
       END)
      -
      (CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
            THEN NULL
            ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
               / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
       END)
    ) / ABS(
      (CASE WHEN (SELECT COALESCE(SUM(conversions),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
            THEN NULL
            ELSE (SELECT SUM(spend)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
               / (SELECT SUM(conversions)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
       END)
    )
  END AS cac_delta_pct,

  CASE
    WHEN (
      CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
           THEN NULL
           ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
              / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
      END
    ) IS NULL THEN NULL
    ELSE (
      (CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)=0
            THEN NULL
            ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
               / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.l30_start AND r.l30_end)
       END)
      -
      (CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
            THEN NULL
            ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
               / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
       END)
    ) / ABS(
      (CASE WHEN (SELECT COALESCE(SUM(spend),0) FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)=0
            THEN NULL
            ELSE (SELECT SUM(revenue)*1.0 FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
               / (SELECT SUM(spend)*1.0   FROM kpi_daily kd, ranges r WHERE kd.date BETWEEN r.p30_start AND r.p30_end)
       END)
    )
  END AS roas_delta_pct;
