{{
    config(
        materialized='incremental',
        unique_key=['survey_key', 'wave_key', 'product_key', 'indication_key', 'metric_date'],
        incremental_strategy='merge',
        cluster_by=['metric_date']
    )
}}

/*
    Fact model: fact_survey_metrics
    Grain: one row per (survey, wave, product, indication, metric_date)
    Purpose: pre-aggregated KPI table that powers the Power BI dashboard
    directly, avoiding an expensive live aggregation over fact_response on
    every dashboard refresh. Sourced from int_survey_metrics_agg.
*/

with agg as (

    select * from {{ ref('int_survey_metrics_agg') }}

    {% if is_incremental() %}
    where metric_date >= (
        select dateadd('day', -{{ var('incremental_lookback_days') }}, max(metric_date))
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

product_dim as (
    select product_key, product_id from {{ ref('dim_product') }}
),

indication_dim as (
    select indication_key, indication_id from {{ ref('dim_indication') }}
),

response_counts as (
    -- completion_rate = distinct respondents who answered / distinct
    -- respondents assigned to that survey+wave (approximated via all
    -- respondents who have at least one response row in the survey/wave,
    -- since panel assignment counts are not separately fed upstream)
    select
        survey_id,
        wave_id,
        count(distinct respondent_id) as total_assigned_respondents
    from {{ ref('int_response_enriched') }}
    group by 1, 2
),

question_dim as (
    select question_id, question_category from {{ ref('dim_question') }}
),

-- Awareness/preference are computed from responses to questions explicitly
-- tagged in that category, rather than left as unpopulated placeholder
-- columns: awareness_pct = % of respondents answering an "awareness"
-- question affirmatively (response_score >= 5 on a 0-10 scale);
-- preference_pct = % answering a "preference" question affirmatively.
category_metrics as (
    select
        r.survey_id,
        r.wave_id,
        r.product_id,
        date_trunc('day', r.response_timestamp)::date as metric_date,
        round(
            sum(iff(qd.question_category = 'awareness' and r.response_score >= 5, 1, 0))::float
            / nullif(sum(iff(qd.question_category = 'awareness', 1, 0)), 0) * 100, 2
        ) as awareness_pct,
        round(
            sum(iff(qd.question_category = 'preference' and r.response_score >= 5, 1, 0))::float
            / nullif(sum(iff(qd.question_category = 'preference', 1, 0)), 0) * 100, 2
        ) as preference_pct
    from {{ ref('int_response_enriched') }} r
    left join question_dim qd on r.question_id = qd.question_id
    where r.response_timestamp is not null
    group by 1, 2, 3, 4
),

final as (

    select
        sv.survey_key,
        w.wave_key,
        p.product_key,
        i.indication_key,
        a.metric_date,
        a.respondent_count,
        round(
            a.respondent_count::float
            / nullif(rc.total_assigned_respondents, 0) * 100, 2
        )                                        as completion_rate,
        round(a.avg_response_score, 2)               as avg_response_score,
        round(a.nps_score, 2)                            as nps_score,
        cm.awareness_pct,
        cm.preference_pct
    from agg a
    inner join survey_dim sv      on a.survey_id = sv.survey_id
    left join wave_dim w          on a.wave_id = w.wave_id
    left join product_dim p       on a.product_id = p.product_id
    left join indication_dim i    on a.indication_id = i.indication_id
    left join response_counts rc  on a.survey_id = rc.survey_id and a.wave_id = rc.wave_id
    left join category_metrics cm
        on a.survey_id = cm.survey_id
       and a.wave_id = cm.wave_id
       and a.product_id = cm.product_id
       and a.metric_date = cm.metric_date

)

select * from final
