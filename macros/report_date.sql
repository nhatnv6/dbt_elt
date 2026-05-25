{# Reporting anchor date. Override via the `report_date` var; else current_date(). #}
{% macro report_date() %}
    {%- set v = var('report_date', none) -%}
    {%- if v -%}
        cast('{{ v }}' as date)
    {%- else -%}
        current_date()
    {%- endif -%}
{% endmacro %}
