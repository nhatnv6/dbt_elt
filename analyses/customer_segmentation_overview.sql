-- Quick-look segmentation summary for the business / BI team.
-- `dbt compile` renders the SQL into `target/compiled/...` for ad-hoc use; it
-- is *not* materialised by `dbt run`.

select
    customer_segment,
    count(*)                                                        as customers,
    round(100.0 * count(*) / sum(count(*)) over (), 2)              as pct_of_book,
    round(avg(tenure_years), 2)                                     as avg_tenure_years,
    round(avg(total_transaction_value), 2)                          as avg_txn_value,
    round(avg(total_credit_limit), 2)                               as avg_credit_limit,
    round(avg(rfm_total_score), 2)                                  as avg_rfm,
    count_if(has_credit_card)                                       as customers_with_cc,
    count_if(has_savings)                                           as customers_with_savings
from {{ ref('customer_360') }}
group by customer_segment
order by customers desc
