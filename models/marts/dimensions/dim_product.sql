/*
    Mart model: dim_product
    Grain: one row per current product_id (SCD Type-2 history lives in
    snapshots/snap_product.sql; this model exposes only the current record
    for simple joins, matching the DDL contract in snowflake/006_tables.sql).
*/

with product as (

    select * from {{ ref('stg_product') }}

),

final as (

    select
        {{ petrf_surrogate_key(['product_id']) }}  as product_key,
        product_id,
        product_name,
        manufacturer,
        molecule,
        therapeutic_class,
        launch_status,
        true                                          as is_current,
        current_timestamp()                              as dbt_valid_from,
        cast(null as timestamp_ntz)                         as dbt_valid_to
    from product

)

select * from final
