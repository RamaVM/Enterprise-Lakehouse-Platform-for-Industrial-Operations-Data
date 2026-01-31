/* =========================================================
   SECTION 1 — BASIC ANALYTICS / VALIDATION
========================================================= */

-- Asset snapshot check (point-in-time)
SELECT
    asset_id,
    status,
    risk
FROM gold_analytics.public.dim_asset_current
WHERE year = 2026
  AND month = 1
  AND day = 7;


-- Daily active vs downtime assets
SELECT
    business_date,
    COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END)   AS active_assets,
    COUNT(CASE WHEN status = 'INACTIVE' THEN 1 END) AS downtime_assets
FROM gold_analytics.public.fact_asset_status_daily
GROUP BY business_date
ORDER BY business_date;


/* =========================================================
   SECTION 2 — MAINTENANCE ANALYTICS
========================================================= */

-- Monthly maintenance cost by plant
SELECT
    a.plant_id,
    f.year,
    f.month,
    SUM(f.total_maintenance_cost) AS monthly_maintenance_cost
FROM gold_analytics.public.fact_maintenance_daily f
JOIN gold_analytics.public.dim_asset_current a
    ON f.asset_id = a.asset_id
GROUP BY a.plant_id, f.year, f.month
ORDER BY f.year, f.month, monthly_maintenance_cost DESC;


-- Top 5 assets by total maintenance spend
SELECT
    asset_id,
    SUM(total_maintenance_cost) AS total_maintenance_cost
FROM gold_analytics.public.fact_maintenance_daily
GROUP BY asset_id
ORDER BY total_maintenance_cost DESC
LIMIT 5;


/* =========================================================
   SECTION 3 — DOWNTIME & RELIABILITY ANALYTICS
========================================================= */

-- Downtime days by asset type (monthly)
SELECT
    d.asset_type,
    s.year,
    s.month,
    COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) AS downtime_days
FROM gold_analytics.public.fact_asset_status_daily s
JOIN gold_analytics.public.dim_asset_current d
    ON s.asset_id = d.asset_id
GROUP BY d.asset_type, s.year, s.month
ORDER BY s.year, s.month;


-- Plants with highest downtime ratio
SELECT
    d.plant_id,
    f.year,
    f.month,
    COUNT(CASE WHEN f.status = 'INACTIVE' THEN 1 END) AS inactive_count,
    COUNT(*)                                         AS total_count,
    ROUND(
        COUNT(CASE WHEN f.status = 'INACTIVE' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS downtime_ratio
FROM gold_analytics.public.fact_asset_status_daily f
JOIN gold_analytics.public.dim_asset_current d
    ON f.asset_id = d.asset_id
GROUP BY d.plant_id, f.year, f.month
ORDER BY downtime_ratio DESC;


/* =========================================================
   SECTION 4 — MAINTENANCE COST vs DOWNTIME EFFECTIVENESS
========================================================= */

-- Maintenance cost vs downtime (plant-level effectiveness)
SELECT
    d.plant_id,
    d.year,
    d.month,
    SUM(f.total_maintenance_cost) AS total_maintenance_cost,
    COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) AS downtime_days,
    COUNT(*) AS total_status_days,
    ROUND(
        COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS downtime_ratio
FROM gold_analytics.public.dim_asset_current d
JOIN gold_analytics.public.fact_maintenance_daily f
    ON d.asset_id = f.asset_id
JOIN gold_analytics.public.fact_asset_status_daily s
    ON d.asset_id = s.asset_id
GROUP BY d.plant_id, d.year, d.month
ORDER BY total_maintenance_cost DESC;


/* =========================================================
   SECTION 5 — BI / DASHBOARD KPIs
========================================================= */

-- Executive KPI: daily plant health
SELECT
    plant_id,
    business_date,
    active_assets,
    downtime_assets,
    (active_assets + downtime_assets) AS total_assets,
    ROUND(
        active_assets * 100.0
        / NULLIF(active_assets + downtime_assets, 0),
        2
    ) AS availability_percentage,
    total_maintenance_cost
FROM gold_analytics.public.kpi_plant_daily_summary
ORDER BY business_date DESC, plant_id;


-- Monthly plant performance (BI trend)
SELECT
    plant_id,
    year,
    month,
    SUM(active_assets)   AS active_asset_days,
    SUM(downtime_assets) AS downtime_asset_days,
    ROUND(
        SUM(active_assets) * 100.0
        / NULLIF(SUM(active_assets + downtime_assets), 0),
        2
    ) AS monthly_availability_pct,
    SUM(total_maintenance_cost) AS monthly_maintenance_cost
FROM gold_analytics.public.kpi_plant_daily_summary
GROUP BY plant_id, year, month
ORDER BY year, month, plant_id;


/* =========================================================
   SECTION 6 — ASSET-LEVEL BI INSIGHTS
========================================================= */

-- Asset effectiveness ranking
SELECT
    d.asset_id,
    d.asset_type,
    d.plant_id,
    COUNT(CASE WHEN s.status = 'ACTIVE' THEN 1 END)   AS active_days,
    COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) AS downtime_days,
    ROUND(
        COUNT(CASE WHEN s.status = 'ACTIVE' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS availability_pct
FROM gold_analytics.public.fact_asset_status_daily s
JOIN gold_analytics.public.dim_asset_current d
    ON s.asset_id = d.asset_id
GROUP BY d.asset_id, d.asset_type, d.plant_id
ORDER BY availability_pct ASC;


-- Risk-based asset performance
SELECT
    d.risk,
    COUNT(DISTINCT d.asset_id) AS asset_count,
    COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) AS total_downtime_days,
    ROUND(
        COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) * 1.0
        / NULLIF(COUNT(DISTINCT d.asset_id), 0),
        2
    ) AS avg_downtime_per_asset
FROM gold_analytics.public.dim_asset_current d
JOIN gold_analytics.public.fact_asset_status_daily s
    ON d.asset_id = s.asset_id
GROUP BY d.risk
ORDER BY avg_downtime_per_asset DESC;


-- Top 10 costly & unreliable assets (executive BI)
SELECT
    d.asset_id,
    d.asset_type,
    d.plant_id,
    SUM(f.total_maintenance_cost) AS total_maintenance_cost,
    COUNT(CASE WHEN s.status = 'INACTIVE' THEN 1 END) AS downtime_days
FROM gold_analytics.public.dim_asset_current d
JOIN gold_analytics.public.fact_maintenance_daily f
    ON d.asset_id = f.asset_id
JOIN gold_analytics.public.fact_asset_status_daily s
    ON d.asset_id = s.asset_id
GROUP BY d.asset_id, d.asset_type, d.plant_id
ORDER BY total_maintenance_cost DESC, downtime_days DESC
LIMIT 10;
