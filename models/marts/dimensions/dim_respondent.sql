/*
    Mart model: dim_respondent
    Grain: one row per respondent_id
    Note: the same respondent can appear across multiple survey exports; the
    grouping below collapses to the latest-loaded attribute values seen for
    that respondent (stg_respondent is already deduplicated to one row per
    respondent_id, so this is a straight pass-through with surrogate key add).
*/

with respondent as (

    select * from {{ ref('stg_respondent') }}

),

final as (

    select
        {{ petrf_surrogate_key(['respondent_id']) }}  as respondent_key,
        respondent_id,
        specialty,
        years_in_practice_bucket,
        region,
        country_code,
        panel_source,
        consent_flag
    from respondent

)

select * from final
