{% macro age_band(age_col) %}
    case
        when {{ age_col }} is null then 'Unknown'
        when {{ age_col }} < 18 then 'Under 18'
        when {{ age_col }} between 18 and 25 then '18-25'
        when {{ age_col }} between 26 and 35 then '26-35'
        when {{ age_col }} between 36 and 50 then '36-50'
        when {{ age_col }} between 51 and 65 then '51-65'
        else '65+'
    end
{% endmacro %}
