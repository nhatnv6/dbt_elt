{{ config(materialized='ephemeral') }}

with ix as (
    select * from {{ ref('silver_crm_interactions') }}
    where not is_interaction_in_future
)

select
    customer_id,
    count(*)                                                              as total_interactions,
    count_if(interaction_type = 'Email')                                  as email_interactions,
    count_if(interaction_type = 'Chat')                                   as chat_interactions,
    count_if(interaction_type = 'Call')                                   as call_interactions,
    min(interaction_date)                                                 as first_interaction_date,
    max(interaction_date)                                                 as last_interaction_date,
    datediff({{ report_date() }}, max(interaction_date))                       as days_since_last_interaction,
    count_if(interaction_date >= date_sub({{ report_date() }}, {{ var('active_customer_window_days') }}))
                                                                          as interactions_last_90d
from ix
group by customer_id
