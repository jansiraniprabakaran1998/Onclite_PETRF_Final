/*
    Staging model: stg_product_indication
    Grain: one row per (product_id, indication_id) pair
*/

with source as (

    select * from {{ source('raw', 'raw_product_indication') }}

),

renamed as (

    select
        trim(product_code_src)          as product_id,
        trim(indication_code_src)          as indication_id,
        case
            when lower(trim(is_primary_indication)) in ('y', 'yes', 'true', '1') then true
            else false
        end                                    as is_primary_indication,
        try_to_date(approval_date, 'YYYY-MM-DD') as approval_date,
        _file_name,
        _loaded_at
    from source
    where product_code_src is not null
      and indication_code_src is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by product_id, indication_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
