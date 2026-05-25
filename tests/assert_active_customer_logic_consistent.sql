-- An active customer must have *some* activity in the last 90 days.
-- This catches mistakes where the segmentation rule drifts away from the flag.

select
    customer_id,
    is_active_customer,
    days_since_last_activity
from {{ ref('customer_360') }}
where is_active_customer = true
  and days_since_last_activity > {{ var('active_customer_window_days') }}
