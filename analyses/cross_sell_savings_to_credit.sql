-- Active customers who hold Savings but no Credit Card — credit card upsell list.
-- Filter to those with strong RFM (recent + frequent + valuable) for best conversion odds.

select
    customer_id,
    full_name,
    email,
    mobile,
    age_band,
    tenure_years,
    total_transaction_value,
    avg_balance,
    rfm_total_score,
    recency_score,
    frequency_score,
    monetary_score
from {{ ref('customer_360') }}
where is_active_customer
  and has_savings
  and not has_credit_card
  and rfm_total_score >= 10
order by rfm_total_score desc, total_transaction_value desc
