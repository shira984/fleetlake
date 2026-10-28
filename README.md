# fleetlake

A small, fully local **open-source lakehouse** for synthetic connected-vehicle telemetry:
Apache Iceberg on S3-compatible storage, queried by Trino, transformed with dbt, orchestrated by Prefect.

It is shaped like the data platform behind a connected-vehicle security product: several OEMs
send telemetry in different schemas. The platform normalizes it into a common model, builds a
per-vehicle state ("digital twin"), and flags anomalies. Along the way it covers the operational
side of a data lake: compaction, snapshot expiry, partition evolution, and data-quality SLAs.

## Architecture

```
generator (Python) ──► PyIceberg ingest ──► Iceberg tables (Parquet on S3)
                                                 ▲          │
                         JDBC catalog (Postgres) ┘          ▼
                                                 Trino ◄── dbt-trino (silver / gold)
                                                   ▲
                                     Prefect (flows, schedules, retries)
```

| Component | Role | Local port |
|---|---|---|
| SeaweedFS | S3-compatible object storage holding the Parquet data and Iceberg metadata files | `9000` (S3 API) |
| Postgres | Iceberg **JDBC catalog** (`iceberg_catalog` db) + Prefect metadata (`prefect` db) | `5434` |
| Trino 476 | MPP SQL engine, Iceberg connector | `8085` |
| Prefect 3 | Orchestration server + UI | `4200` |

All ports bind to `127.0.0.1`. Credentials in `.env.example` are local-only placeholders.

## Quick start

Requires Docker with about 4 GB of memory available (Trino is capped at 3 GB).

```bash
make up      # start everything, wait for healthchecks
make smoke   # create an Iceberg table through Trino, write, read, inspect $snapshots/$files, drop
make trino-cli
```

- S3 API: http://localhost:9000 (`aws --endpoint-url http://localhost:9000 s3 ls s3://warehouse --recursive`)
- Trino UI: http://localhost:8085 (any username)
- Prefect UI: http://localhost:4200

## Design choices

- **JDBC catalog on Postgres, not a REST catalog (Nessie, Lakekeeper, Polaris).** It means one
  fewer service, and both Trino and PyIceberg's `SqlCatalog` speak it natively. In production a
  REST catalog would be the better pick: it adds central access control, multi-engine credential
  vending, and catalog-level commits.
- **SeaweedFS as the S3 stand-in.** MinIO stopped publishing community container images in 2025.
  Everything talks plain S3 (path-style), so swapping in AWS S3 is a config change.
- **PyIceberg for ingestion, not Spark.** Ingestion is Python-native and light. Trino does the
  heavy SQL. This setup has no JVM batch cluster to run.
- **dbt-trino for transformations.** It brings SQL models, tests, and lineage on top of Trino.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).
