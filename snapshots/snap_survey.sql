{% snapshot snap_survey %}

{{
    config(
        target_schema='snapshots',
        unique_key='survey_id',
        strategy='timestamp',
        updated_at='_loaded_at',
        invalidate_hard_deletes=True
    )
}}

/*
    Snapshot: snap_survey
    Purpose: tracks changes to survey metadata over time - most commonly
    close_date being backfilled once fielding wraps, or fielding_vendor
    corrections. Useful for auditing "when did we learn this survey closed".
*/

select
    survey_id_src as survey_id,
    survey_name,
    survey_type,
    indication_code,
    wave_code,
    launch_date,
    close_date,
    fielding_vendor,
    _loaded_at
from {{ source('raw', 'raw_survey') }}

{% endsnapshot %}
