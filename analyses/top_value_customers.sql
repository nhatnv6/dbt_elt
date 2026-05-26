-- Top Private and Priority Customers, ranked by transaction value.
-- Use for relationship-manager assignment and exclusive-offer lists.

select
    customer_id,
    full_name,
    email,
    customer_segment,
    age_band,
    tenure_years,
    total_products,
    total_transaction_value,
    total_inflow,
    total_outflow,
    current_balance,
    total_credit_limit,
    credit_utilisation_ratio,
    rfm_total_score,
    last_activity_date
from {{ ref('customer_360') }}
where customer_segment in ('Private Customer', 'Priority Customer')
order by total_transaction_value desc
limit 500
