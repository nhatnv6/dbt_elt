{{
    config(
        materialized='incremental',
        file_format='delta',
        incremental_strategy='append'
    )
}}

-- Append a fresh snapshot once per day. Source has no updated_at, so
-- snapshot_date is our version key. Silver picks the latest snapshot
-- per customer_id.

select
    cast(customer_id   as bigint)  as customer_id,
    cast(first_name    as string)  as first_name,
    cast(last_name     as string)  as last_name,
    cast(email         as string)  as email,
    cast(mobile        as string)  as mobile,
    cast(gender        as string)  as gender,
    cast(date_of_birth as date)    as date_of_birth,
    cast(signup_date   as date)    as signup_date,
    current_date()                 as snapshot_date,
    current_timestamp()            as _ingested_at
from {{ ref('customer_raw') }}
{% if is_incremental() %}
where current_date() > (
    select coalesce(max(snapshot_date), date '1900-01-01') from {{ this }}
)
{% endif %}
