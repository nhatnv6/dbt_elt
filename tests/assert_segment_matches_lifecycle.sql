-- Segmentation invariant: a Churned/Dormant/At-Risk customer must not also
-- be classified into an Active segment, and vice versa.

select
    customer_id,
    customer_segment,
    lifecycle_stage,
    is_active_customer
from {{ ref('customer_360') }}
where (customer_segment in ('VIP', 'Premium', 'Mainstream Credit', 'Mainstream Saver')
       and is_active_customer = false)
   or (customer_segment in ('Churned', 'Dormant', 'At Risk')
       and is_active_customer = true)
