-- Every transaction must belong to a known customer & known product.
-- Returns offending transaction_ids; test passes when zero rows are returned.

select
    t.transaction_id,
    t.customer_id,
    t.product_id
from {{ ref('silver_transactions') }} t
left join {{ ref('silver_customers') }}            c on c.customer_id = t.customer_id
left join {{ ref('silver_product_enrollments') }}  p on p.product_id  = t.product_id
where c.customer_id is null
   or p.product_id  is null
