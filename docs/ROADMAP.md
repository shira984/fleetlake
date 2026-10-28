# Roadmap

Each phase lands as its own PR and must run end to end before the next one starts.

| # | Phase | Status |
|---|---|---|
| 0 | **Skeleton.** Compose stack (SeaweedFS S3, Postgres JDBC catalog, Trino, Prefect server), Makefile, smoke test | done |
| 1 | **Telemetry generator.** 3 OEMs with different payload schemas, VINs, GPS (PII), late / out-of-order / duplicate events, injected anomalies (impossible GPS jumps, abnormal API-call bursts) | |
| 2 | **Bronze ingest.** PyIceberg appends raw events into Iceberg with hidden partitioning (`day(event_ts)`, `bucket(vin)`) | |
| 3 | **dbt-trino.** Silver: normalize all OEMs to one common model, dedup, incremental merge for late data. Gold: per-vehicle daily state ("digital twin") + detections | |
| 4 | **Prefect.** Flows and deployments for generate, ingest, dbt build, and checks, with a worker, retries, and a schedule | |
| 5 | **Lake operations.** Compaction (`optimize`), `expire_snapshots`, `remove_orphan_files`, time travel, partition evolution, `EXPLAIN ANALYZE` before/after, freshness + quality SLAs | |
| 6 | **Write-ups.** Delta vs Iceberg, Airflow vs Prefect, Spark vs Trino, catalog choices, how this runs on Kubernetes (Prefect K8s workers, Trino Helm chart, requests/limits) | |
