{{
    config(
        materialized='incremental',
        file_format='delta',
        unique_key='product_id',
        incremental_strategy='merge',
        liquid_clustered_by=['customer_id', 'product_id']
    )
}}

with bronze_new as (
    select * from {{ ref('bronze_product_enrollments') }}
    {% if is_incremental() %}
    where _ingested_at > (
        select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }}
    )
    {% endif %}
),

latest as (
    select *
    from bronze_new
    qualify row_number() over (partition by product_id order by _ingested_at desc) = 1
)

select
    product_id,
    customer_id,
    initcap(trim(product_type))             as product_type,
    enrollment_date,
    `limit`                                 as credit_limit,
    _ingested_at                            as updated_at,

    (initcap(trim(product_type)) = 'Credit Card' and `limit` <= 0)
                                            as is_credit_card_zero_limit
from latest
