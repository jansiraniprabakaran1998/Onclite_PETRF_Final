/*
    Mart model: dim_indication
    Grain: one row per indication_id
*/

with indication as (

    select * from {{ ref('stg_indication') }}

),

final as (

    select
        {{ petrf_surrogate_key(['indication_id']) }}  as indication_key,
        indication_id,
        indication_name,
        therapeutic_area,
        icd10_code
    from indication

)

select * from final
