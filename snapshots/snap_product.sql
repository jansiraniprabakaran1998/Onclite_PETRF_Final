{% snapshot snap_product %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='_loaded_at',
        invalidate_hard_deletes=True
    )
}}

/*
    Snapshot: snap_product
    Purpose: full SCD Type-2 change history for products, e.g. when a product
    moves from 'pre_launch' to 'launched', or manufacturer/molecule metadata
    is corrected. dim_product exposes only the current row for simple joins;
    this snapshot is queried directly for point-in-time or "what changed and
    when" analysis (e.g. "what was launch_status as of the Wave 3 field date").
*/

select
    product_code_src as product_id,
    product_name,
    manufacturer,
    molecule,
    therapeutic_class,
    launch_status,
    _loaded_at
from {{ source('raw', 'raw_product') }}

{% endsnapshot %}
