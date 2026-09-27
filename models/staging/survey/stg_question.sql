/*
    Staging model: stg_question
    Grain: one row per question_id
*/

with source as (

    select * from {{ source('raw', 'raw_question') }}

),

renamed as (

    select
        trim(question_id_src)          as question_id,
        trim(survey_id_src)               as survey_id,
        trim(question_text)                  as question_text,
        lower(trim(question_type))              as question_type,
        trim(question_category)                    as question_category,
        nullif(trim(product_code_ref), '')             as product_id,
        _file_name,
        _loaded_at
    from source
    where question_id_src is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (
        partition by question_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
