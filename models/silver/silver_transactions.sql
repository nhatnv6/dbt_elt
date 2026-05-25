{{
    config(
        materialized='incremental',
        file_format='delta',
        unique_key='transaction_id',
        incremental_strategy='merge',
        liquid_clustered_by=['customer_id', 'transaction_date']
    )
}}

with bronze_new as (
    select * from {{ ref('bronze_transactions') }}
    {% if is_incremental() %}
    where _ingested_at > (
        select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }}
    )
    {% endif %}
),

latest as (
    select *
    from bronze_new
    qualify row_number() over (partition by transaction_id order by _ingested_at desc) = 1
)

select
    transaction_id,
    product_id,
    customer_id,
    transaction_amount,
    closing_balance,
    transaction_ts,
    cast(transaction_ts as date)             as transaction_date,
    case when transaction_amount >= 0 then 'Credit' else 'Debit' end as transaction_direction,
    abs(transaction_amount)                  as transaction_abs_amount,
    _ingested_at                             as updated_at,
    transaction_ts > current_timestamp()     as is_transaction_in_future
from latest
