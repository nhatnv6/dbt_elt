{# Use the +schema value verbatim instead of the default
   "<target.schema>_<custom_schema>" concatenation.
   Result: +schema: raw  ->  raw  (not gold_raw). #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
