{{
    config(
        materialized='incremental',
        file_format='delta',
        incremental_strategy='append'
    )
}}

-- NOTE: enrollment_date doesn't change on credit-limit updates,
-- so those updates are missed until the source ships an updated_at.

select
    cast(product_id      as bigint)  as product_id,
    cast(customer_id     as bigint)  as customer_id,
    cast(product_type    as string)  as product_type,
    cast(enrollment_date as date)    as enrollment_date,
    cast(`limit`         as double)  as `limit`,
    current_timestamp()              as _ingested_at
from {{ ref('product_enrollments') }}
{% if is_incremental() %}
where enrollment_date >=
    {% if var('backfill_enrollment_date', none) %}
        cast('{{ var("backfill_enrollment_date") }}' as date)
    {% else %}
        (select coalesce(max(enrollment_date), date '1900-01-01') from {{ this }})
    {% endif %}
{% endif %}
