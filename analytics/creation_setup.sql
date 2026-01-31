/* =========================================================
   WAREHOUSE
========================================================= */
CREATE WAREHOUSE IF NOT EXISTS gold_wh
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

/* =========================================================
   DATABASE & SCHEMAS
========================================================= */
CREATE DATABASE IF NOT EXISTS gold_analytics;

CREATE SCHEMA IF NOT EXISTS gold_analytics.public;
CREATE SCHEMA IF NOT EXISTS gold_analytics.bi;

/* =========================================================
   STORAGE INTEGRATION
========================================================= */
CREATE OR REPLACE STORAGE INTEGRATION gold_s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::015903982676:role/snowflake_gold_s3_role'
STORAGE_ALLOWED_LOCATIONS = ('s3://enterprise-lakehouse-data/gold/');

DESC STORAGE INTEGRATION gold_s3_int;

/* =========================================================
   STAGE
========================================================= */
CREATE STAGE IF NOT EXISTS gold_stage
URL = 's3://enterprise-lakehouse-data/gold/'
STORAGE_INTEGRATION = gold_s3_int
FILE_FORMAT = (TYPE = PARQUET);

/* =========================================================
   EXTERNAL TABLES (GOLD)
========================================================= */

CREATE OR REPLACE EXTERNAL TABLE dim_asset_current (
    asset_id STRING          AS (VALUE:asset_id::STRING),
    asset_type STRING        AS (VALUE:asset_type::STRING),
    plant_id STRING          AS (VALUE:plant_id::STRING),
    capacity_mw NUMBER(10,2) AS (VALUE:capacity_mw::NUMBER(10,2)),
    status STRING            AS (VALUE:status::STRING),
    risk STRING              AS (VALUE:risk::STRING),
    last_updated_date DATE   AS (VALUE:last_updated_date::DATE),

    year  INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'year=([0-9]{4})',1,1,'e',1))),
    month INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'month=([0-9]{1,2})',1,1,'e',1))),
    day   INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'day=([0-9]{1,2})',1,1,'e',1)))
)
LOCATION = @gold_stage/dim_asset_current/
FILE_FORMAT = (TYPE = PARQUET)
AUTO_REFRESH = FALSE;


CREATE OR REPLACE EXTERNAL TABLE dim_asset_scd (
    asset_id STRING,
    plant_id STRING,
    asset_type STRING,
    capacity_mw NUMBER(10,2),
    status STRING,
    risk STRING,
    effective_from TIMESTAMP_NTZ,
    effective_to TIMESTAMP_NTZ,
    is_current BOOLEAN,
    asset_event_hash STRING,

    year  INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'year=([0-9]{4})',1,1,'e',1))),
    month INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'month=([0-9]{1,2})',1,1,'e',1))),
    day   INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'day=([0-9]{1,2})',1,1,'e',1)))
)
LOCATION = @gold_stage/dim_asset_scd/
FILE_FORMAT = (TYPE = PARQUET)
AUTO_REFRESH = FALSE;


CREATE OR REPLACE EXTERNAL TABLE fact_asset_status_daily (
    business_date DATE,
    asset_id STRING,
    status STRING,

    year  INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'year=([0-9]{4})',1,1,'e',1))),
    month INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'month=([0-9]{1,2})',1,1,'e',1))),
    day   INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'day=([0-9]{1,2})',1,1,'e',1)))
)
LOCATION = @gold_stage/fact_asset_status_daily/
FILE_FORMAT = (TYPE = PARQUET)
AUTO_REFRESH = FALSE;


CREATE OR REPLACE EXTERNAL TABLE fact_maintenance_daily (
    business_date DATE,
    asset_id STRING,
    total_maintenance_cost NUMBER(18,2),
    maintenance_count NUMBER(38,0),

    year  INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'year=([0-9]{4})',1,1,'e',1))),
    month INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'month=([0-9]{1,2})',1,1,'e',1))),
    day   INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'day=([0-9]{1,2})',1,1,'e',1)))
)
LOCATION = @gold_stage/fact_maintenance_daily/
FILE_FORMAT = (TYPE = PARQUET)
AUTO_REFRESH = FALSE;


CREATE OR REPLACE EXTERNAL TABLE kpi_plant_daily_summary (
    plant_id STRING,
    business_date DATE,
    active_assets NUMBER,
    downtime_assets NUMBER,
    avg_capacity NUMBER(10,2),
    total_maintenance_cost NUMBER(18,2),

    year  INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'year=([0-9]{4})',1,1,'e',1))),
    month INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'month=([0-9]{1,2})',1,1,'e',1))),
    day   INTEGER AS (TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME,'day=([0-9]{1,2})',1,1,'e',1)))
)
LOCATION = @gold_stage/kpi_plant_daily_summary/
FILE_FORMAT = (TYPE = PARQUET)
AUTO_REFRESH = FALSE;

/* =========================================================
   BI TABLES (MATERIALIZED FOR ANALYTICS)
========================================================= */

CREATE OR REPLACE TABLE gold_analytics.bi.dim_asset_scd_BI AS
SELECT * FROM dim_asset_scd;

CREATE OR REPLACE TABLE gold_analytics.bi.dim_asset_current_BI AS
SELECT * FROM dim_asset_current;

CREATE OR REPLACE TABLE gold_analytics.bi.fact_asset_status_daily_BI AS
SELECT * FROM fact_asset_status_daily;

CREATE OR REPLACE TABLE gold_analytics.bi.fact_maintenance_daily_BI AS
SELECT * FROM fact_maintenance_daily;

CREATE OR REPLACE TABLE gold_analytics.bi.kpi_plant_daily_summary_BI AS
SELECT * FROM kpi_plant_daily_summary;
