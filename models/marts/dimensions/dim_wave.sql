/*
    Mart model: dim_wave
    Grain: one row per distinct wave_id
    Note: PETRF source systems do not export a standalone wave file - wave_id
    arrives embedded on each survey record (stg_survey.wave_id). This model
    derives the wave dimension from the distinct wave codes observed, and
    computes wave_sequence + start/end bounds from the surveys assigned to
    each wave. If a dedicated wave_master feed is added upstream, only this
    model needs to change - downstream fact tables are insulated via wave_key.
*/

with survey_waves as (

    select
        wave_id,
        min(launch_date)  as wave_start_date,
        max(close_date)      as wave_end_date
    from {{ ref('stg_survey') }}
    where wave_id is not null
    group by 1

),

sequenced as (

    select
        wave_id,
        wave_start_date,
        wave_end_date,
        dense_rank() over (order by wave_start_date asc) as wave_sequence
    from survey_waves

),

final as (

    select
        {{ petrf_surrogate_key(['wave_id']) }}  as wave_key,
        wave_id,
        wave_id                                    as wave_code,
        wave_sequence,
        wave_start_date,
        wave_end_date
    from sequenced

)

select * from final
