-- customer_360 must have exactly one row per customer present in silver_customers.

with c as (select count(*) as n from {{ ref('silver_customers') }}),
     g as (select count(*) as n from {{ ref('customer_360') }})
select
    c.n as silver_customers_count,
    g.n as customer_360_count
from c, g
where c.n <> g.n
