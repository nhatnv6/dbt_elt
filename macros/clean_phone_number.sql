{# PH mobile to E.164: 09xxxxxxxxx -> +63xxxxxxxxxx. NULL if not a valid format. #}
{% macro clean_phone_number(column_name) %}
    case
        when {{ column_name }} is null then null
        when length(regexp_replace({{ column_name }}, '[^0-9]', '')) = 11
             and regexp_replace({{ column_name }}, '[^0-9]', '') like '09%'
            then concat('+63', substring(regexp_replace({{ column_name }}, '[^0-9]', ''), 2))
        when length(regexp_replace({{ column_name }}, '[^0-9]', '')) = 12
             and regexp_replace({{ column_name }}, '[^0-9]', '') like '639%'
            then concat('+', regexp_replace({{ column_name }}, '[^0-9]', ''))
        else null
    end
{% endmacro %}
