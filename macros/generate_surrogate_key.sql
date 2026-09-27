{% macro petrf_surrogate_key(field_list) %}
{#-
    Wraps dbt_utils.generate_surrogate_key with a project-standard null
    handling policy (controlled by the `surrogate_key_treat_nulls_as_empty_strings`
    var), so every mart model hashes keys identically instead of each model
    author picking its own convention.
-#}
    {{ dbt_utils.generate_surrogate_key(field_list) }}
{% endmacro %}
