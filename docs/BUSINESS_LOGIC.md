# Business Logic

Definitions for `customer_360`. All thresholds are project vars in
`dbt_project.yml` — change rules there, not in SQL.

## Report date

All recency metrics anchor on the `report_date` var, set via
`--vars '{report_date: "2025-07-01"}'`. If unset, the `report_date()`
macro falls back to `current_date()`. The value is also surfaced as the
`report_date` column on `customer_360`.

## Active customer

A customer is **active** if they have any transaction or interaction in
the last 90 days (`active_customer_window_days`).

| Days since last activity | `lifecycle_stage` |
| ------------------------ | ----------------- |
| 0–90                     | Active            |
| 91–180                   | At Risk           |
| 181–365                  | Hibernate         |
| 365+ or never            | Churned           |

## Segmentation

Order matters — first match wins.

| Segment             | Rule                                                                |
| ------------------- | ------------------------------------------------------------------- |
| Churned             | not active, lifecycle = Churned                                     |
| Hibernate           | not active, lifecycle = Hibernate                                   |
| At Risk             | not active, lifecycle = At Risk                                     |
| Private Customer    | active, `total_transaction_value ≥ 100,000`                         |
| Priority Customer   | active, `total_transaction_value ≥ 50,000`                          |
| Mainstream Credit   | active, holds Credit Card                                           |
| Mainstream Saver    | active, holds Savings                                               |
| Prospect            | no products                                                         |
| Other               | catch-all (should be empty)                                         |

The table is partitioned by `customer_segment` since dashboards almost
always filter on it.

## Metrics

* **`total_transaction_value`** — sum of *absolute* amounts (both credits
  and debits contribute).
* **`total_inflow` / `total_outflow`** — signed splits.
* **`txns_last_90d` / `txn_value_last_90d`** — rolling 90-day window.
* **`current_balance` / `avg_balance` / `min_balance` / `max_balance`** —
  from `closing_balance` on the transaction stream.
* **`credit_utilisation_ratio`** — `total_outflow / total_credit_limit`.
  A proxy; true utilisation needs statement data. NULL if no credit limit.
* **RFM scores** — `ntile(5)` on recency, frequency, monetary. Higher = better.
  Sum gives `rfm_total_score` (3–15).

## Demographics

* `age_years` from `date_of_birth` vs `report_date`.
* `age_band`: Under 18, 18-25, 26-35, 36-50, 51-65, 65+.
* `tenure_days` / `tenure_years` from `signup_date`.
