{{ config(materialized='ephemeral') }}

with txn as (
    select * from {{ ref('silver_transactions') }}
    where not is_transaction_in_future
),
as_of as (select {{ reporting_as_of_date() }} as as_of_date)

select
    t.customer_id,
    count(*)                                                              as total_transactions,
    count_if(t.transaction_direction = 'Credit')                          as credit_transactions,
    count_if(t.transaction_direction = 'Debit')                           as debit_transactions,
    sum(t.transaction_abs_amount)                                         as total_transaction_value,
    sum(case when t.transaction_direction = 'Credit' then t.transaction_amount else 0 end)
                                                                          as total_inflow,
    sum(case when t.transaction_direction = 'Debit'  then t.transaction_abs_amount else 0 end)
                                                                          as total_outflow,
    avg(t.transaction_abs_amount)                                         as avg_transaction_value,
    max(t.transaction_abs_amount)                                         as max_transaction_value,
    min(t.transaction_date)                                               as first_transaction_date,
    max(t.transaction_date)                                               as last_transaction_date,
    datediff(a.as_of_date, max(t.transaction_date))                       as days_since_last_transaction,
    count_if(t.transaction_date >= date_sub(a.as_of_date, {{ var('active_customer_window_days') }}))
                                                                          as txns_last_90d,
    sum(case
            when t.transaction_date >= date_sub(a.as_of_date, {{ var('active_customer_window_days') }})
            then t.transaction_abs_amount else 0 end)                     as txn_value_last_90d
from txn t
cross join as_of a
group by t.customer_id, a.as_of_date
