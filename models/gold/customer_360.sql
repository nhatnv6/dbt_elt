{{
    config(
        materialized='table',
        file_format='delta',
        partition_by=['customer_segment'],
        tblproperties={
            'delta.autoOptimize.optimizeWrite': 'true',
            'delta.autoOptimize.autoCompact':   'true'
        }
    )
}}

with
    cust    as (select * from {{ ref('silver_customers') }}),
    products as (select * from {{ ref('int_customer_products') }}),
    txn     as (select * from {{ ref('int_customer_transactions') }}),
    ix      as (select * from {{ ref('int_customer_interactions') }}),
    as_of   as (select {{ reporting_as_of_date() }} as as_of_date),

joined as (
    select
        c.customer_id,
        a.as_of_date,

        -- identity
        c.first_name,
        c.last_name,
        c.full_name,
        c.email,
        c.mobile_e164                                                            as mobile,
        c.gender,
        c.date_of_birth,
        cast(floor(months_between(a.as_of_date, c.date_of_birth) / 12) as int)   as age_years,

        -- tenure
        c.signup_date,
        datediff(a.as_of_date, c.signup_date)                                    as tenure_days,
        cast(datediff(a.as_of_date, c.signup_date) / 365.25 as decimal(6, 2))    as tenure_years,

        -- products
        coalesce(p.total_products,        0)        as total_products,
        coalesce(p.savings_products,      0)        as savings_products,
        coalesce(p.credit_card_products,  0)        as credit_card_products,
        coalesce(p.total_credit_limit,    0.0)      as total_credit_limit,
        coalesce(p.max_credit_limit,      0.0)      as max_credit_limit,
        p.product_types_held,
        coalesce(p.has_savings,          false)     as has_savings,
        coalesce(p.has_credit_card,      false)     as has_credit_card,
        coalesce(p.is_multi_product,     false)     as is_multi_product,
        p.first_enrollment_date,
        p.last_enrollment_date,

        -- transactions
        coalesce(t.total_transactions,        0)    as total_transactions,
        coalesce(t.credit_transactions,       0)    as credit_transactions,
        coalesce(t.debit_transactions,        0)    as debit_transactions,
        coalesce(t.total_transaction_value,   0.0)  as total_transaction_value,
        coalesce(t.total_inflow,              0.0)  as total_inflow,
        coalesce(t.total_outflow,             0.0)  as total_outflow,
        t.avg_transaction_value,
        t.max_transaction_value,
        t.first_transaction_date,
        t.last_transaction_date,
        t.days_since_last_transaction,
        coalesce(t.txns_last_90d,             0)    as txns_last_90d,
        coalesce(t.txn_value_last_90d,        0.0)  as txn_value_last_90d,

        -- crm
        coalesce(i.total_interactions,        0)    as total_interactions,
        coalesce(i.email_interactions,        0)    as email_interactions,
        coalesce(i.chat_interactions,         0)    as chat_interactions,
        coalesce(i.call_interactions,         0)    as call_interactions,
        i.first_interaction_date,
        i.last_interaction_date,
        i.days_since_last_interaction,
        coalesce(i.interactions_last_90d,     0)    as interactions_last_90d,

        -- dq passthrough
        c.is_email_invalid,
        c.is_mobile_invalid,
        c.is_dob_in_future,
        c.is_signup_before_dob
    from cust c
    cross join as_of a
    left join products p on p.customer_id = c.customer_id
    left join txn      t on t.customer_id = c.customer_id
    left join ix       i on i.customer_id = c.customer_id
),

enriched as (
    select
        *,
        {{ age_band('age_years') }}                                              as age_band,

        least(
            coalesce(days_since_last_transaction, 99999),
            coalesce(days_since_last_interaction, 99999)
        )                                                                        as days_since_last_activity,

        greatest(
            coalesce(last_transaction_date, date '1900-01-01'),
            coalesce(last_interaction_date, date '1900-01-01')
        )                                                                        as last_activity_date,

        least(
            coalesce(days_since_last_transaction, 99999),
            coalesce(days_since_last_interaction, 99999)
        ) <= {{ var('active_customer_window_days') }}                            as is_active_customer,

        case
            when total_transactions = 0 and total_interactions = 0 then 'Never Engaged'
            when least(
                coalesce(days_since_last_transaction, 99999),
                coalesce(days_since_last_interaction, 99999)
            ) <= {{ var('active_customer_window_days') }} then 'Active'
            when least(
                coalesce(days_since_last_transaction, 99999),
                coalesce(days_since_last_interaction, 99999)
            ) <= {{ var('dormant_window_days') }}        then 'At Risk'
            when least(
                coalesce(days_since_last_transaction, 99999),
                coalesce(days_since_last_interaction, 99999)
            ) <= {{ var('churn_window_days') }}          then 'Dormant'
            else 'Churned'
        end                                                                      as lifecycle_stage,

        case
            when total_credit_limit > 0
            then cast(total_outflow / total_credit_limit as decimal(10, 4))
        end                                                                      as credit_utilisation_ratio
    from joined
),

scored as (
    select
        *,
        ntile(5) over (
            order by case when is_active_customer then days_since_last_activity end desc nulls last
        )                                                                        as recency_score,
        ntile(5) over (order by total_transactions)                              as frequency_score,
        ntile(5) over (order by total_transaction_value)                         as monetary_score
    from enriched
)

select
    *,
    coalesce(recency_score, 1) + coalesce(frequency_score, 1) + coalesce(monetary_score, 1)
        as rfm_total_score,

    case
        when not is_active_customer and lifecycle_stage = 'Churned'  then 'Churned'
        when not is_active_customer and lifecycle_stage = 'Dormant'  then 'Dormant'
        when not is_active_customer and lifecycle_stage = 'At Risk'  then 'At Risk'
        when total_credit_limit >= 100000 and is_active_customer     then 'VIP'
        when is_multi_product   and is_active_customer               then 'Premium'
        when has_credit_card    and is_active_customer               then 'Mainstream Credit'
        when has_savings        and is_active_customer               then 'Mainstream Saver'
        when total_products = 0                                      then 'Prospect'
        else 'Other'
    end                                                                          as customer_segment,

    current_timestamp()                                                          as _dbt_loaded_at
from scored
