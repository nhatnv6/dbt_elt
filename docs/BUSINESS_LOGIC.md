# Business Logic

Definitions for `customer_360`. All thresholds are project vars in
`dbt_project.yml` — change rules there, not in SQL.

## As-of date

All recency metrics anchor on a single `reporting_as_of_date` var so
re-runs are deterministic. In prod, the orchestrator sets this to the
previous business day.

## Active customer

A customer is **active** if they have any transaction or interaction in
the last 90 days (`active_customer_window_days`).

| Days since last activity | `lifecycle_stage` |
| ------------------------ | ----------------- |
| 0–90                     | Active            |
| 91–180                   | At Risk           |
| 181–365                  | Dormant           |
| 365+                     | Churned           |
| no activity ever         | Never Engaged     |

## Segmentation

Order matters — first match wins.

| Segment             | Rule                                                 |
| ------------------- | ---------------------------------------------------- |
| Churned             | not active, lifecycle = Churned                      |
| Dormant             | not active, lifecycle = Dormant                      |
| At Risk             | not active, lifecycle = At Risk                      |
| VIP                 | active and `total_credit_limit ≥ 100,000`            |
| Premium             | active and holds both Savings and Credit Card        |
| Mainstream Credit   | active and holds Credit Card                         |
| Mainstream Saver    | active and holds Savings                             |
| Prospect            | no products                                          |
| Other               | catch-all (should be empty)                          |

The table is partitioned by `customer_segment` since dashboards almost
always filter on it.

## Metrics

* **`total_transaction_value`** — sum of *absolute* amounts (both credits
  and debits contribute).
* **`total_inflow` / `total_outflow`** — signed splits.
* **`txns_last_90d` / `txn_value_last_90d`** — rolling 90-day window.
* **`credit_utilisation_ratio`** — `total_outflow / total_credit_limit`.
  A proxy; true utilisation needs statement data. NULL if no credit limit.
* **RFM scores** — `ntile(5)` on recency, frequency, monetary. Higher = better.
  Sum gives `rfm_total_score` (3–15).

## Demographics

* `age_years` derived from `date_of_birth` against `as_of_date`.
* `age_band` buckets: Under 18, 18-25, 26-35, 36-50, 51-65, 65+.
* `tenure_days` / `tenure_years` from `signup_date`.
