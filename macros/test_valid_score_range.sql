{% test valid_score_range(model, column_name, min_value=0, max_value=10) %}
{#-
    Custom generic test: fails if any non-null value in `column_name` falls
    outside [min_value, max_value]. Used on response_score / avg_response_score
    columns across staging, intermediate, and mart layers so the bound check
    is defined once and reused via a single macro call in each schema.yml.
-#}

select *
from {{ model }}
where {{ column_name }} is not null
  and ({{ column_name }} < {{ min_value }} or {{ column_name }} > {{ max_value }})

{% endtest %}
