{% macro is_valid_email(column_name) %}
    (
        {{ column_name }} is not null
        and {{ column_name }} rlike '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    )
{% endmacro %}
