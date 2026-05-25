{{
    config(
        materialized='incremental',
        file_format='delta',
        unique_key='interaction_id',
        incremental_strategy='merge',
        liquid_clustered_by=['customer_id', 'interaction_date']
    )
}}

with bronze_new as (
    select * from {{ ref('bronze_crm_interactions') }}
    {% if is_incremental() %}
    where _ingested_at > (
        select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }}
    )
    {% endif %}
),

latest as (
    select *
    from bronze_new
    qualify row_number() over (partition by interaction_id order by _ingested_at desc) = 1
)

select
    interaction_id,
    customer_id,
    initcap(trim(interaction_type))      as interaction_type,
    interaction_date,
    _ingested_at                         as updated_at,
    interaction_date > current_date()    as is_interaction_in_future
from latest
