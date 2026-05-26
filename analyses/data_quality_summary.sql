-- DQ flag counts surfaced on customer_360.
-- Track these over time to monitor source-data hygiene.

select
    count(*)                                       as total_customers,
    count_if(is_email_invalid)                     as invalid_email_count,
    count_if(missing_phone_number_flag)            as missing_phone_count,
    round(100.0 * count_if(is_email_invalid) / count(*), 2)        as pct_invalid_email,
    round(100.0 * count_if(missing_phone_number_flag) / count(*), 2) as pct_missing_phone
from {{ ref('customer_360') }}
