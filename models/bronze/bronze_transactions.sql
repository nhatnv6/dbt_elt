{{
    config(
        materialized='incremental',
        file_format='delta',
        incremental_strategy='append'
    )
}}

select
    cast(transaction_id     as bigint)     as transaction_id,
    cast(product_id         as bigint)     as product_id,
    cast(customer_id        as bigint)     as customer_id,
    cast(transaction_amount as double)     as transaction_amount,
    cast(closing_balance    as double)     as closing_balance,
    cast(transaction_date   as timestamp)  as transaction_ts,
    current_timestamp()                    as _ingested_at
from {{ ref('transaction_history') }}
{% if is_incremental() %}
where cast(transaction_date as timestamp) >=
    {% if var('backfill_transaction_date', none) %}
        cast('{{ var("backfill_transaction_date") }}' as timestamp)
    {% else %}
        (select coalesce(max(transaction_ts), timestamp '1900-01-01') from {{ this }})
    {% endif %}
{% endif %}
