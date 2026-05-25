# Bank Customer 360

dbt + Databricks project that unifies customer behaviour across Savings,
Credit Cards, CRM interactions, and transactions into a single
`customer_360` gold table for BI and marketing.

## Layout

```
seeds/             raw CSVs (gitignored; drop your dataset here)
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
| bronze | `incremental` + `append` (customers daily snapshot) |
| silver | `incremental` + `merge` on natural key     |
| gold   | `table` (customer_360 partitioned by `customer_segment`) |

See [docs/BUSINESS_LOGIC.md](docs/BUSINESS_LOGIC.md) for metric and segmentation rules,
[docs/DATA_MODEL.md](docs/DATA_MODEL.md) for lineage, and
[docs/DATA_QUALITY.md](docs/DATA_QUALITY.md) for DQ.

## Running

```bash
cp profiles.yml.example ~/.dbt/profiles.yml
export DATABRICKS_TOKEN=dapi...

dbt deps
dbt seed                 # loads seeds/*.csv into <schema>_raw
dbt build                # bronze -> silver -> gold + tests
dbt docs generate && dbt docs serve
```

Drop the four CSVs (`customer_raw.csv`, `product_enrollments.csv`,
`crm_interactions.csv`, `transaction_history.csv`) into `seeds/` before
the first run. They're gitignored — too large for VCS.

## Backfills

```bash
# backfill a specific table from a date
dbt run --select bronze_transactions+ \
        --vars '{backfill_transaction_date: "2025-04-01"}'

# nuclear option: rebuild from scratch
dbt run --select bronze+ --full-refresh
```

## Switching to real sources in prod

The bronze models read seeds via `ref()`. In prod, swap to `source()`:

```diff
-from {{ ref('customer_raw') }}
+from {{ source('raw', 'customer_raw') }}
```

`models/bronze/_sources.yml` already declares the sources.

## Key columns in `customer_360`

| Question                       | Column                                         |
| ------------------------------ | ---------------------------------------------- |
| Active?                        | `is_active_customer`, `lifecycle_stage`        |
| What do they hold?             | `total_products`, `has_*`                      |
| How much value?                | `total_transaction_value`, `total_inflow/outflow` |
| Last touch?                    | `last_activity_date`, `days_since_last_activity` |
| Who to target?                 | `customer_segment`, `rfm_total_score`          |
| Credit risk signal?            | `credit_utilisation_ratio`                     |
