/*
    Staging model: stg_indication
    Grain: one row per indication_code
*/

with source as (

    select * from {{ source('raw', 'raw_indication') }}

),

renamed as (

    select
        trim(indication_code_src)      as indication_id,
        trim(indication_name)             as indication_name,
        trim(therapeutic_area)               as therapeutic_area,
        upper(trim(icd10_code))                 as icd10_code,
        _file_name,
        _loaded_at
    from source
    where indication_code_src is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by indication_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
