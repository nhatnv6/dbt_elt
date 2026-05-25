{{
    config(
        materialized='incremental',
        file_format='delta',
        incremental_strategy='append'
    )
}}

-- Append-only. Watermark from --vars 'backfill_interaction_date: ...'
-- if set, otherwise from the latest row already loaded.

select
    cast(interaction_id   as bigint)  as interaction_id,
    cast(customer_id      as bigint)  as customer_id,
    cast(interaction_type as string)  as interaction_type,
    cast(interaction_date as date)    as interaction_date,
    current_timestamp()               as _ingested_at
from {{ ref('crm_interactions') }}
{% if is_incremental() %}
where interaction_date >=
    {% if var('backfill_interaction_date', none) %}
        cast('{{ var("backfill_interaction_date") }}' as date)
    {% else %}
        (select coalesce(max(interaction_date), date '1900-01-01') from {{ this }})
    {% endif %}
{% endif %}
