{# Reporting anchor date. Override via `reporting_as_of_date` var; else current_date(). #}
{% macro reporting_as_of_date() %}
    {%- set v = var('reporting_as_of_date', none) -%}
    {%- if v -%}
        cast('{{ v }}' as date)
    {%- else -%}
        current_date()
    {%- endif -%}
{% endmacro %}
