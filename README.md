Enterprise Lakehouse Platform for Industrial Operations Data

Batch · Incremental · Governed · Replayable



Overview

This project implements an enterprise-grade data lakehouse platform designed to ingest messy, multi-source operational data, apply data quality and governance controls, handle late data and corrections, and serve analytics-ready datasets through Snowflake.

The platform is intentionally batch-oriented and stateful, reflecting how real industrial and enterprise systems operate — not demo-style event streams.

The project emphasizes:

Correctness over speed

Governance over convenience

Recoverability over one-time success

Cost-aware cloud usage




 Problem Statement

In real industrial environments (manufacturing, utilities, infrastructure):

Data comes from multiple upstream systems

Data is delivered as batch snapshots

Data frequently contains:

Missing values

Invalid ranges

Duplicate records

Late-arriving corrections

Schema changes without notice

Pipelines often fail due to:

Lack of replay strategy

Poor data quality handling

No auditability

Tight coupling between ingestion and processing

This project addresses these challenges by building a resilient, auditable, and rebuildable lakehouse architecture.




High-Level Architecture
Synthetic Source APIs
        ↓
Kafka (ingestion buffer only)
        ↓
Amazon S3 — Bronze (raw, immutable)
        ↓
Databricks — Silver (validation & quarantine)
        ↓
Databricks — Curated Silver (SCD Type 2)
        ↓
Databricks — Gold (business models)
        ↓
Snowflake (analytics & serving)


Core Principles

Stateless compute, stateful storage

Immutable raw data

Idempotent processing

Rebuildable downstream layers

Explicit data governance



Repository Structure
enterprise-lakehouse/
├── api/
│   └── asset_api.py
|       data_generator.py
|       maintenance_api.py
|       reference_api.py
│
├── kafka/
│   └── producrs
           |__producer_asset.py
              producer_maintenance.py
              producer_reference.py


├── ingestion/
        checkpoint_manager.py  
        file_writer.py
        kafka_to_s3_consumer.py  
│
├── transformation/
            bronze to silver (2).ipynb
            bRONZE TO SILVER.ipynb
            RECONCILIATION, REPLAY SAFETY & SCD LOGIC.ipynb"
            RECONCILIATION, REPLAY SAFETY & SCD_LOGIC_maintenance_snapshots.ipynb"
            SCD TO GOLD.ipynb"
│
├── metadata/
        PIPELINE RUN METADATA.ipynb
│
├── sql/
│   └── 
        analytics.sql"
        creation_setup.sql"
│
├── architecture/
│   ├── architecture.png
│   ├── data_flow_diagram.png
│   └── step8_observability.md
│
├
│
└── README.md

🔌 Data Sources (Synthetic by Design)

The platform uses synthetic upstream APIs to simulate real enterprise systems.

Why Synthetic APIs?

Full control over data quality issues

Schema evolution simulation

Late and corrected data

Reproducible scenarios

No dependency on third-party APIs

Source Types

Asset snapshots (slow-changing master data)

Maintenance snapshots (mutable operational data)

Reference / lookup data (versioned)

All sources intentionally generate dirty and inconsistent data.

🧵 Kafka Ingestion

Kafka is used strictly as an ingestion buffer.

Kafka Responsibilities

Decouple source systems from storage

Preserve raw payloads

Enable replay and backfill

Kafka Does NOT Perform

Transformations

Joins

Streaming analytics

Business logic

Each source writes to a dedicated topic with a business-key-based message key.

🗄️ Data Lake Design (Amazon S3)
Bronze Layer — Raw & Immutable

Exact payloads from Kafka

Append-only

Partitioned by ingestion date

System of record for replay

Silver Layer — Validated & Governed

Schema enforcement

Null, domain, and range checks

Hashing and deduplication

Invalid records sent to quarantine

Curated Silver — Temporal Correctness

SCD Type 2 applied

Late-arriving data handled

Historical accuracy preserved

Replay-safe and idempotent

Gold Layer — Analytics Ready

Business-aligned dimensions and facts

Partitioned by business date

Optimized file sizes

Stable analytics contract

✅ Data Quality & Governance
Validation Framework

Required field (null) checks

Domain checks (enum validation)

Range checks (numeric and date)

Schema version enforcement

Quarantine

Invalid records are never dropped

Stored with explicit failure reasons

Reprocessable after correction

PII Handling

Sensitive fields masked or hashed in Silver

Gold layer exposes only safe attributes

🔁 Incremental Processing & Idempotency

Watermark-based incremental ingestion

Hash-based deduplication

Deterministic transformations

Safe re-runs without duplication

🕰️ SCD & Late Data Handling

SCD Type 2 used for stateful entities

Historical versions preserved

Late corrections update correct time windows

Current and historical views remain consistent

📊 Gold Layer Modeling
Gold Table Types

Dimensions (current-state views)

Fact tables (time-based measures)

KPI / aggregate tables

Optimization Techniques

Partition pruning

Join strategy selection

File size tuning

Atomic write patterns

❄️ Snowflake Serving Layer

Snowflake is used as a read-only analytics engine.

Practices

External tables over Gold Parquet data

Auto-suspend warehouses

Partition-aware queries

No access to Bronze or Silver layers

📈 Observability & Audits
Metrics Captured

Records read and written

Validation failures

Deduplication counts

Late data metrics

SCD version counts

Audits

Bronze → Silver reconciliation

Silver → Gold reconciliation

Daily data consistency checks

All metadata is stored under the metadata/ directory.

🔄 Failure, Replay & Backfill

The platform supports:

Safe job restarts

Full and partial replays

Date-range backfills

Deterministic rebuilds from Bronze

Failures never corrupt downstream layers.

💰 Cost Control Strategy

EC2 used only for ingestion and stopped when idle

No always-on compute resources

Databricks used only for batch processing

Snowflake auto-suspends when idle

Partition pruning enforced for analytics queries

🧠 Key Outcomes

This project demonstrates:

Enterprise lakehouse architecture

Data quality engineering

Incremental batch processing

Temporal correctness with SCD

Observability and auditability

Cost-aware cloud design

End-to-end data ownership

🧑‍💼 Interview Summary (30 seconds)

“I built an enterprise batch lakehouse platform that ingests messy multi-source operational data, enforces data quality and schema governance, handles late data and corrections using SCD Type 2, and serves analytics through Snowflake with full observability, replay, and cost control.”

📌 Final Note

This project prioritizes correctness, governance, and explainability over speed or buzzwords and reflects how real enterprise data platforms are designed and operated.