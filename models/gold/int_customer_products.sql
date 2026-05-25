{{ config(materialized='ephemeral') }}

select
    customer_id,
    count(*)                                                                    as total_products,
    count_if(product_type = 'Savings')                                          as savings_products,
    count_if(product_type = 'Credit Card')                                      as credit_card_products,
    sum(case when product_type = 'Credit Card' then credit_limit else 0 end)    as total_credit_limit,
    max(case when product_type = 'Credit Card' then credit_limit end)           as max_credit_limit,
    min(enrollment_date)                                                        as first_enrollment_date,
    max(enrollment_date)                                                        as last_enrollment_date,
    array_sort(collect_set(product_type))                                       as product_types_held,
    max(case when product_type = 'Savings'     then 1 else 0 end) = 1           as has_savings,
    max(case when product_type = 'Credit Card' then 1 else 0 end) = 1           as has_credit_card,
    (count_if(product_type = 'Savings') > 0 and count_if(product_type = 'Credit Card') > 0)
                                                                                as is_multi_product
from {{ ref('silver_product_enrollments') }}
group by customer_id
