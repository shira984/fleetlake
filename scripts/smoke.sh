#!/usr/bin/env bash
# End-to-end wiring check: Trino -> JDBC catalog (Postgres) -> Parquet files in S3 (SeaweedFS).
# Creates a throwaway table, writes, reads, inspects Iceberg metadata, then drops it.
# Statements are batched so the Trino CLI JVM starts only three times.
set -euo pipefail

# Pipe SQL on stdin into one CLI call. The CLI warns about a missing TTY; drop that noise, keep real errors.
trino() { docker compose exec -T trino trino --output-format=TSV 2> >(grep -vE "jline|dumb terminal" >&2); }

cleanup() {
  trino <<'SQL' >/dev/null 2>&1 || true
DROP TABLE IF EXISTS iceberg.smoke.ping;
DROP SCHEMA IF EXISTS iceberg.smoke;
SQL
}
trap cleanup EXIT

echo "-> create, write"
trino <<'SQL' >/dev/null
CREATE SCHEMA IF NOT EXISTS iceberg.smoke;
DROP TABLE IF EXISTS iceberg.smoke.ping;
CREATE TABLE iceberg.smoke.ping (id INTEGER, ts TIMESTAMP(6)) WITH (partitioning = ARRAY['day(ts)']);
INSERT INTO iceberg.smoke.ping VALUES (1, TIMESTAMP '2026-01-01 10:00:00'), (2, TIMESTAMP '2026-01-02 10:00:00');
SQL

echo "-> read + Iceberg metadata"
read -r rows snapshots files < <(trino <<'SQL'
SELECT
  (SELECT count(*) FROM iceberg.smoke.ping),
  (SELECT count(*) FROM iceberg.smoke."ping$snapshots"),
  (SELECT count(*) FROM iceberg.smoke."ping$files");
SQL
)
echo "   rows=$rows snapshots=$snapshots data_files=$files"
[ "$rows" = "2" ] || { echo "expected 2 rows, got: $rows" >&2; exit 1; }
[ "$files" = "2" ] || { echo "expected 2 data files (one per day partition), got: $files" >&2; exit 1; }

echo "smoke OK (cleanup runs on exit)"
