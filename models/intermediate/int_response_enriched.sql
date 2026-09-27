/*
    Intermediate model: int_response_enriched
    Grain: one row per response_id
    Purpose: joins stg_response to stg_question (to resolve product_id when
    not directly present on the response record) and stg_survey (to resolve
    wave_id). Ephemeral - inlined into downstream marts at compile time so it
    never lands as its own table, keeping the warehouse footprint lean for a
    purely intermediate join.
*/

with responses as (

    select * from {{ ref('stg_response') }}

),

questions as (

    select
        question_id,
        product_id as question_product_id
    from {{ ref('stg_question') }}

),

surveys as (

    select
        survey_id,
        wave_id
    from {{ ref('stg_survey') }}

),

enriched as (

    select
        r.response_id,
        r.survey_id,
        s.wave_id,
        r.respondent_id,
        r.question_id,
        coalesce(r.product_id, q.question_product_id)   as product_id,
        r.response_value,
        r.response_score,
        r.response_timestamp,
        r._loaded_at
    from responses r
    left join questions q on r.question_id = q.question_id
    left join surveys s   on r.survey_id = s.survey_id

)

select * from enriched
