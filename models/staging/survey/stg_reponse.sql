/*
    Staging model: stg_response
    Grain: one row per response_id (respondent's answer to one question)
    Purpose: type-cast response_score with bound checking, parse timestamp,
             deduplicate. This is the highest-volume staging model; it stays
             a view here (materialization is cheap at this layer) with the
             heavy incremental-merge work happening in the FACT_RESPONSE
             mart model instead, per dbt best practice of keeping staging
             thin and pushing incremental logic to marts.
*/

with source as (

    select * from {{ source('raw', 'raw_response') }}

),

renamed as (

    select
        trim(response_id_src)                as response_id,
        trim(survey_id_src)                     as survey_id,
        trim(respondent_id_src)                    as respondent_id,
        trim(question_id_src)                         as question_id,
        nullif(trim(product_code_ref), '')               as product_id,
        response_value,
        try_to_number(response_score, 10, 2)                as response_score_raw,
        try_to_timestamp_ntz(response_timestamp)               as response_timestamp,
        _file_name,
        _loaded_at
    from source
    where response_id_src is not null

),

validated as (

    select
        *,
        case
            when response_score_raw is null then null
            when response_score_raw between {{ var('min_valid_response_score') }}
                                     and {{ var('max_valid_response_score') }}
                then response_score_raw
            else null  -- out-of-bound scores are nulled here and caught by
                       -- the dbt_expectations range test below for alerting
        end as response_score
    from renamed

),

deduplicated as (

    select *
    from validated
    qualify row_number() over (
        partition by response_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
