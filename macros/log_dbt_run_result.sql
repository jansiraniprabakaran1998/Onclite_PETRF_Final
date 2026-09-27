{% macro log_dbt_run_results(results) %}
{#-
    Fires from dbt_project.yml's on-run-end hook. Writes one row per model
    result into AUDIT.DBT_RUN_SUMMARY so pipeline health can be queried
    alongside Python/Task run history in a single audit table family
    (see snowflake/006_tables.sql and snowflake/010_views.sql).
    No-ops gracefully outside of Snowflake target or during `dbt compile`.
-#}
{% if execute and results %}
    {% set insert_statements = [] %}
    {% for result in results %}
        {% set model_name = result.node.name | replace("'", "''") %}
        {% set status = result.status | replace("'", "''") %}
        {% set materialization = result.node.config.materialized | replace("'", "''") %}
        {% set rows_affected = result.adapter_response.get('rows_affected', 0) if result.adapter_response else 0 %}
        {% set exec_time = result.execution_time | round(2) %}

        {% set stmt %}
            select
                '{{ invocation_id }}'      as invocation_id,
                '{{ model_name }}'          as model_name,
                '{{ status }}'                as status,
                {{ rows_affected }}             as rows_affected,
                {{ exec_time }}                   as execution_time_seconds,
                '{{ run_started_at }}'::timestamp_ntz as run_started_at,
                '{{ materialization }}'                 as materialization
        {% endset %}
        {% do insert_statements.append(stmt) %}
    {% endfor %}

    {% if insert_statements %}
        {% set full_insert %}
            insert into {{ target.database }}.audit.dbt_run_summary
                (invocation_id, model_name, status, rows_affected,
                 execution_time_seconds, run_started_at, materialization)
            {{ insert_statements | join(' union all ') }}
        {% endset %}
        {% do run_query(full_insert) %}
    {% endif %}
{% endif %}
{% endmacro %}
