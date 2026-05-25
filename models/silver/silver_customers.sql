{{
    config(
        materialized='incremental',
        file_format='delta',
        unique_key='customer_id',
        incremental_strategy='merge',
        liquid_clustered_by=['customer_id']
    )
}}

with bronze_new as (
    select * from {{ ref('bronze_customers') }}
    {% if is_incremental() %}
    where _ingested_at > (
        select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }}
    )
    {% endif %}
),

latest as (
    select *
    from bronze_new
    qualify row_number() over (partition by customer_id order by _ingested_at desc) = 1
)

select
    customer_id,
    initcap(trim(first_name))                                            as first_name,
    initcap(trim(last_name))                                             as last_name,
    concat_ws(' ', initcap(trim(first_name)), initcap(trim(last_name))) as full_name,
    case when {{ is_valid_email('lower(trim(email))') }}
         then lower(trim(email)) end                                     as email,
    {{ clean_phone_number('mobile') }}                                   as mobile_e164,
    case
        when upper(trim(gender)) in ('M', 'MALE')   then 'Male'
        when upper(trim(gender)) in ('F', 'FEMALE') then 'Female'
        else 'Unknown'
    end                                                                  as gender,
    date_of_birth,
    signup_date,
    _ingested_at                                                         as updated_at,

    not {{ is_valid_email('lower(trim(email))') }}                       as is_email_invalid,
    (mobile is null or trim(mobile) = '')                                as missing_phone_number_flag
from latest
