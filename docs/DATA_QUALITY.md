# Data Quality

Approach: **flag, don't drop.** Bad rows keep flowing; offending fields
are nulled and a boolean flag is set. The exception is future-dated
transactions / interactions, which are excluded from rollups because
they'd skew aggregates.

## Flags surfaced

| Layer / column                          | Flag                         |
| --------------------------------------- | ---------------------------- |
| `silver_customers.email`                | `is_email_invalid`           |
| `silver_customers.mobile_e164`          | `is_mobile_invalid`          |
| `silver_customers.date_of_birth`        | `is_dob_in_future`           |
| `silver_customers`                      | `is_signup_before_dob`       |
| `silver_product_enrollments`            | `is_credit_card_zero_limit`  |
| `silver_crm_interactions.interaction_date` | `is_interaction_in_future` |
| `silver_transactions.transaction_ts`    | `is_transaction_in_future`   |

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

DQ flag columns are not currently tested. Add tests as the team decides
which conditions should warn vs. fail the build.
