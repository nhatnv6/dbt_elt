-- Per-segment CRM channel mix.
-- Tells marketing which channel to lead with for each segment.

with channel_totals as (
    select
        customer_segment,
        sum(email_interactions) as email_total,
        sum(chat_interactions)  as chat_total,
        sum(call_interactions)  as call_total
    from {{ ref('customer_360') }}
    group by customer_segment
)

select
    customer_segment,
    email_total,
    chat_total,
    call_total,
    email_total + chat_total + call_total as total_interactions,
    round(100.0 * email_total / nullif(email_total + chat_total + call_total, 0), 1) as pct_email,
    round(100.0 * chat_total  / nullif(email_total + chat_total + call_total, 0), 1) as pct_chat,
    round(100.0 * call_total  / nullif(email_total + chat_total + call_total, 0), 1) as pct_call,
    case
        when email_total >= chat_total and email_total >= call_total then 'Email'
        when chat_total  >= call_total                               then 'Chat'
        else 'Call'
    end as preferred_channel
from channel_totals
order by total_interactions desc
