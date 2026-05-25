select
    customer_id,
    customer_segment,
    lifecycle_stage,
    is_active_customer
from {{ ref('customer_360') }}
where (customer_segment in ('Priority Customer', 'Private Customer', 'Mainstream Credit', 'Mainstream Saver')
       and is_active_customer = false)
   or (customer_segment in ('Churned', 'Hibernate', 'At Risk')
       and is_active_customer = true)
