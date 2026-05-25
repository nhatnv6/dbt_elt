# Data Quality

Approach: **flag, don't drop.** Bad rows keep flowing; offending fields
are nulled and a boolean flag is set. The exception is future-dated
transactions / interactions, which are excluded from rollups because
they'd skew aggregates.

## Flags surfaced

| Column                                  | Flag                          |
| --------------------------------------- | ----------------------------- |
| `silver_customers.email`                | `is_email_invalid`            |
| `silver_customers.mobile`               | `missing_phone_number_flag`   |

(Future-dated interactions / transactions are filtered out internally
by the gold rollups; the corresponding silver flags exist only for that
filtering and are not surfaced.)

## Tests

Generic (in `_*_models.yml`):
- `not_null` / `unique` on natural keys
- `accepted_values` on categoricals
- `relationships` for FKs across silver
- `dbt_utils.accepted_range` for non-negative measures
- `dbt_utils.expression_is_true` invariants on `customer_360`

Singular (in `tests/`):
- `assert_active_customer_logic_consistent.sql`
- `assert_segment_matches_lifecycle.sql`
- `assert_no_orphan_transactions.sql`
- `assert_customer_360_row_count_matches_customers.sql`
