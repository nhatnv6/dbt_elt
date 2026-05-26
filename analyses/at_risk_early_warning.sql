-- Active customers trending toward "At Risk": last activity 60–90 days ago.
-- Use this list for proactive retention campaigns (email, call, offer).

select
    customer_id,
    full_name,
    email,
    mobile,
    customer_segment,
    days_since_last_activity,
    last_activity_date,
    total_transaction_value,
    total_credit_limit,
    rfm_total_score
from {{ ref('customer_360') }}
where is_active_customer
  and days_since_last_activity between 60 and 90
order by total_transaction_value desc
