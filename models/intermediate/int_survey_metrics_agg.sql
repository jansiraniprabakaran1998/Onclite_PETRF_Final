/*
    Intermediate model: int_survey_metrics_agg
    Grain: one row per (survey_id, wave_id, product_id, indication_id, metric_date)
    Purpose: pre-aggregates response-level data into the KPIs that
    fact_survey_metrics persists. Kept separate from the mart model so the
    aggregation logic can be unit-tested independently (see tests/) without
    depending on the incremental merge behavior of the fact table itself.
*/

with responses as (

    select * from {{ ref('int_response_enriched') }}

),

surveys as (

    select survey_id, indication_id from {{ ref('stg_survey') }}

),

joined as (

    select
        r.survey_id,
        r.wave_id,
        r.product_id,
        s.indication_id,
        date_trunc('day', r.response_timestamp)::date as metric_date,
        r.respondent_id,
        r.response_score,
        -- NPS-eligible responses are on questions tagged 'nps' upstream;
        -- approximated here via score range 0-10 with promoter/detractor split
        case when r.response_score >= 9 then 1 else 0 end as is_promoter,
        case when r.response_score <= 6 then 1 else 0 end as is_detractor
    from responses r
    left join surveys s on r.survey_id = s.survey_id
    where r.response_timestamp is not null

),

aggregated as (

    select
        survey_id,
        wave_id,
        product_id,
        indication_id,
        metric_date,
        count(distinct respondent_id)                                   as respondent_count,
        avg(response_score)                                                as avg_response_score,
        -- NPS = %promoters - %detractors, scaled to -100..100
        (sum(is_promoter)::float / nullif(count(*), 0)
         - sum(is_detractor)::float / nullif(count(*), 0)) * 100            as nps_score
    from joined
    group by 1, 2, 3, 4, 5

)

select * from aggregated
