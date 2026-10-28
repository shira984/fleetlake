#!/usr/bin/env bash
# End-to-end wiring check: Trino -> JDBC catalog (Postgres) -> Parquet files in S3 (SeaweedFS).
# Creates a throwaway table, writes, reads, inspects Iceberg metadata, then drops it.
set -euo pipefail

# The Trino CLI warns about a missing TTY on every call; drop that noise, keep real errors.
trino() { docker compose exec -T trino trino --output-format=TSV --execute "$1" 2> >(grep -vE "jline|dumb terminal" >&2); }

echo "-> create schema + table"
trino "CREATE SCHEMA IF NOT EXISTS iceberg.smoke"
trino "DROP TABLE IF EXISTS iceberg.smoke.ping"
trino "CREATE TABLE iceberg.smoke.ping (id INTEGER, ts TIMESTAMP(6)) WITH (partitioning = ARRAY['day(ts)'])"

echo "-> write"
trino "INSERT INTO iceberg.smoke.ping VALUES (1, TIMESTAMP '2026-01-01 10:00:00'), (2, TIMESTAMP '2026-01-02 10:00:00')"

echo "-> read"
rows=$(trino "SELECT count(*) FROM iceberg.smoke.ping")
[ "$rows" = "2" ] || { echo "expected 2 rows, got: $rows" >&2; exit 1; }

echo "-> Iceberg metadata"
snapshots=$(trino "SELECT count(*) FROM iceberg.smoke.\"ping\$snapshots\"")
files=$(trino "SELECT count(*) FROM iceberg.smoke.\"ping\$files\"")
echo "   snapshots=$snapshots data_files=$files (one file per day partition)"
[ "$files" = "2" ] || { echo "expected 2 data files, got: $files" >&2; exit 1; }

echo "-> cleanup"
trino "DROP TABLE iceberg.smoke.ping"
trino "DROP SCHEMA iceberg.smoke"

echo "smoke OK"
