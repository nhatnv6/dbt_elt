# Bank Customer 360

## Layout

```
seeds/             raw CSVs (your dataset here)
models/
  bronze/          source -> raw, append-only history
  silver/          raw   -> cleansed, current state per natural key
  gold/            silver -> business-ready aggregates + customer_360
macros/
tests/
docs/
```

| Layer  | Materialization                            |
| ------ | ------------------------------------------ |
| bronze | `incremental` + `append` (customers daily snapshot + CDC by date) |
| silver | `incremental` + `merge` on natural key     |
| gold   | `table` (customer_360) |

See [docs/BUSINESS_LOGIC.md](docs/BUSINESS_LOGIC.md) for metric and segmentation rules,
[docs/DATA_MODEL.md](docs/DATA_MODEL.md) for lineage, and
[docs/DATA_QUALITY.md](docs/DATA_QUALITY.md) for DQ.

## Setup

One-time, in the project root:

```bash
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install dbt-core dbt-databricks
export DATABRICKS_TOKEN=...
```
Configure `~/.dbt/profiles.yml` (host, http_path, catalog, token).

## Running

```bash
dbt deps                 # install dbt_utils + dbt_expectations
dbt seed                 # loads seeds/*.csv into <schema>_raw
dbt build                # bronze -> silver -> gold + tests
```

## Backfills

```bash
# backfill a specific table from a date
dbt run --select bronze_transactions+ --vars '{backfill_transaction_date: "2025-04-01"}'

# nuclear option: rebuild from scratch
dbt run --full-refresh
```