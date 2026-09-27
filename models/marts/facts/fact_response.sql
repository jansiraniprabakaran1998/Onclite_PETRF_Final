{{
    config(
        materialized='incremental',
        unique_key='response_id',
        incremental_strategy='merge',
        cluster_by=['survey_key', 'load_date']
    )
}}

/*
    Fact model: fact_response
    Grain: one row per respondent's answer to one question (response_id)
    Incremental: keyed on response_id with a lookback window (var
    incremental_lookback_days) to absorb late-arriving / corrected rows
    without a full-refresh, matching FACT_RESPONSE contract in
    snowflake/006_tables.sql.
*/

with response as (

    select * from {{ ref('int_response_enriched') }}

    {% if is_incremental() %}
    where _loaded_at >= (
        select dateadd('day', -{{ var('incremental_lookback_days') }}, max(_loaded_at))
        from {{ this }}
    )
    {% endif %}

),

survey_dim as (
    select survey_key, survey_id from {{ ref('dim_survey') }}
),

wave_dim as (
    select wave_key, wave_id from {{ ref('dim_wave') }}
),

respondent_dim as (
    select respondent_key, respondent_id from {{ ref('dim_respondent') }}
),

question_dim as (
    select question_key, question_id from {{ ref('dim_question') }}
),

product_dim as (
    select product_key, product_id from {{ ref('dim_product') }}
),

final as (

    select
        r.response_id,
        sv.survey_key,
        w.wave_key,
        rd.respondent_key,
        q.question_key,
        p.product_key,
        r.response_value,
        r.response_score,
        r.response_timestamp,
        current_date()           as load_date,
        r._loaded_at
    from response r
    inner join survey_dim sv     on r.survey_id = sv.survey_id
    left join wave_dim w         on r.wave_id = w.wave_id
    inner join respondent_dim rd on r.respondent_id = rd.respondent_id
    inner join question_dim q    on r.question_id = q.question_id
    left join product_dim p      on r.product_id = p.product_id

)

select * from final
