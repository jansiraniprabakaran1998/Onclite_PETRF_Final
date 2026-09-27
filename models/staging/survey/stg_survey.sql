/*
    Staging model: stg_survey
    Grain: one row per survey_id
    Purpose: type-cast and rename raw_survey columns, deduplicate on natural key.
*/

with source as (

    select * from {{ source('raw', 'raw_survey') }}

),

renamed as (

    select
        trim(survey_id_src)                        as survey_id,
        trim(survey_name)                             as survey_name,
        lower(trim(survey_type))                         as survey_type,
        trim(indication_code)                              as indication_id,
        trim(wave_code)                                      as wave_id,
        try_to_date(launch_date, 'YYYY-MM-DD')                 as launch_date,
        try_to_date(close_date, 'YYYY-MM-DD')                    as close_date,
        trim(fielding_vendor)                                      as fielding_vendor,
        _file_name,
        _loaded_at
    from source
    where survey_id_src is not null

),

deduplicated as (

    -- Keep the most recently loaded record per natural key in case a
    -- corrected file re-lands the same survey_id.
    select *
    from renamed
    qualify row_number() over (
        partition by survey_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
