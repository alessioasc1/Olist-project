WITH sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
),

geolocation AS (
    SELECT * FROM {{ ref('stg_geolocation') }}
)

SELECT
    s.seller_id,
    ANY_VALUE(s.zip_code_prefix) AS zip_code_prefix,
    COALESCE(ANY_VALUE(g.city), ANY_VALUE(s.city)) AS city,
    COALESCE(ANY_VALUE(g.state), ANY_VALUE(s.state)) AS state,
    COALESCE(ANY_VALUE(g.latitude), 0.0) AS latitude,
    COALESCE(ANY_VALUE(g.longitude), 0.0) AS longitude
FROM sellers s
LEFT JOIN geolocation g 
    ON s.zip_code_prefix = g.zip_code_prefix
GROUP BY s.seller_id