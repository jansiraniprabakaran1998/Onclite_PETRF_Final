{% macro query_comment(node) %}
{#-
    Injects a JSON comment into every query dbt issues to Snowflake, so that
    QUERY_HISTORY can be filtered by app/model/invocation without needing
    Snowsight's query tag UI. Mirrors the pattern dbt Cloud uses natively.
-#}
{%- set comment_dict = {} -%}
{%- do comment_dict.update(
    app='dbt',
    dbt_version=dbt_version,
    project_name=project_name,
    target_name=target.name,
    invocation_id=invocation_id
) -%}
{%- if node is not none -%}
    {%- do comment_dict.update(
        node_id=node.unique_id,
        node_name=node.name,
        resource_type=node.resource_type,
    ) -%}
{%- endif -%}
{{ return(tojson(comment_dict)) }}
{% endmacro %}
