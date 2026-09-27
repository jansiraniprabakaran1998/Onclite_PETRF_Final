/*
    Staging model: stg_respondent
    Grain: one row per respondent_id
    Purpose: type-cast, bucket years_in_practice, normalize consent flag,
             deduplicate. No direct-identifier PII columns exist in the raw
             feed by contract with the fielding vendor - this model documents
             that assumption and would be the enforcement point if it changed.
*/

with source as (

    select * from {{ source('raw', 'raw_respondent') }}

),

renamed as (

    select
        trim(respondent_id_src)               as respondent_id,
        trim(survey_id_src)                      as survey_id,
        trim(specialty)                             as specialty,
        try_to_number(years_in_practice)               as years_in_practice,
        upper(trim(region))                               as region,
        upper(trim(country_code))                            as country_code,
        trim(panel_source)                                     as panel_source,
        case
            when lower(trim(consent_flag)) in ('y', 'yes', 'true', '1') then true
            when lower(trim(consent_flag)) in ('n', 'no', 'false', '0') then false
            else null
        end                                                        as consent_flag,
        _file_name,
        _loaded_at
    from source
    where respondent_id_src is not null

),

bucketed as (

    select
        *,
        case
            when years_in_practice is null then 'unknown'
            when years_in_practice < 5 then '0-4 years'
            when years_in_practice < 10 then '5-9 years'
            when years_in_practice < 20 then '10-19 years'
            else '20+ years'
        end as years_in_practice_bucket
    from renamed

),

deduplicated as (

    select *
    from bucketed
    qualify row_number() over (
        partition by respondent_id
        order by _loaded_at desc
    ) = 1

)

select * from deduplicated
