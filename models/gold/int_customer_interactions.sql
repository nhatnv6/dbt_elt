{{ config(materialized='ephemeral') }}

with ix as (
    select * from {{ ref('silver_crm_interactions') }}
    where not is_interaction_in_future
),
as_of as (select {{ reporting_as_of_date() }} as as_of_date)

select
    i.customer_id,
    count(*)                                                              as total_interactions,
    count_if(i.interaction_type = 'Email')                                as email_interactions,
    count_if(i.interaction_type = 'Chat')                                 as chat_interactions,
    count_if(i.interaction_type = 'Call')                                 as call_interactions,
    min(i.interaction_date)                                               as first_interaction_date,
    max(i.interaction_date)                                               as last_interaction_date,
    datediff(a.as_of_date, max(i.interaction_date))                       as days_since_last_interaction,
    count_if(i.interaction_date >= date_sub(a.as_of_date, {{ var('active_customer_window_days') }}))
                                                                          as interactions_last_90d
from ix i
cross join as_of a
group by i.customer_id, a.as_of_date
