/*
    Mart bridge model: product_indication
    Grain: one row per (product_key, indication_key)
    Resolves the many-to-many relationship between DIM_PRODUCT and
    DIM_INDICATION, e.g. an oncology drug approved across multiple tumor types.
*/

with bridge as (

    select * from {{ ref('stg_product_indication') }}

),

product as (
    select product_key, product_id from {{ ref('dim_product') }}
),

indication as (
    select indication_key, indication_id from {{ ref('dim_indication') }}
),

final as (

    select
        {{ petrf_surrogate_key(['p.product_key', 'i.indication_key']) }}  as product_indication_key,
        p.product_key,
        i.indication_key,
        b.is_primary_indication,
        b.approval_date
    from bridge b
    inner join product p     on b.product_id = p.product_id
    inner join indication i  on b.indication_id = i.indication_id

)

select * from final
