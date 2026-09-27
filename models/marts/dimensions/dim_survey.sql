/*
    Mart model: dim_survey
    Grain: one row per survey_id
*/

with survey as (

    select * from {{ ref('stg_survey') }}

),

final as (

    select
        {{ petrf_surrogate_key(['survey_id']) }}  as survey_key,
        survey_id,
        survey_name,
        survey_type,
        fielding_vendor,
        launch_date,
        close_date
    from survey

)

select * from final
