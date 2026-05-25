{{ config(materialized='ephemeral') }}

with txn as (
    select * from {{ ref('silver_transactions') }}
    where not is_transaction_in_future
),

latest_balance as (
    select customer_id, closing_balance as current_balance
    from txn
    qualify row_number() over (partition by customer_id order by transaction_ts desc) = 1
)

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

    -- balance
    max(lb.current_balance)                                               as current_balance,
    avg(t.closing_balance)                                                as avg_balance,
    min(t.closing_balance)                                                as min_balance,
    max(t.closing_balance)                                                as max_balance,

    min(t.transaction_date)                                               as first_transaction_date,
    max(t.transaction_date)                                               as last_transaction_date,
    datediff({{ report_date() }}, max(t.transaction_date))                     as days_since_last_transaction,
    count_if(t.transaction_date >= date_sub({{ report_date() }}, {{ var('active_customer_window_days') }}))
                                                                          as txns_last_90d,
    sum(case
            when t.transaction_date >= date_sub({{ report_date() }}, {{ var('active_customer_window_days') }})
            then t.transaction_abs_amount else 0 end)                     as txn_value_last_90d
from txn t
left join latest_balance lb on lb.customer_id = t.customer_id
group by t.customer_id
