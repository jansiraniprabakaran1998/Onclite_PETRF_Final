/*
    Staging model: stg_product
    Grain: one row per product_code
*/

with source as (

    select * from {{ source('raw', 'raw_product') }}

),

renamed as (

    select
        trim(product_code_src)        as product_id,
        trim(product_name)               as product_name,
        trim(manufacturer)                  as manufacturer,
        trim(molecule)                         as molecule,
        trim(therapeutic_class)                   as therapeutic_class,
        initcap(trim(launch_status))                 as launch_status,
        _file_name,
        _loaded_at
    from source
    where product_code_src is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by product_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
