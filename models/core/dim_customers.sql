WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

geolocation AS (
    SELECT * FROM {{ ref('stg_geolocation') }}
)

SELECT
    c.customer_id_per_transaction,
    c.customer_unique_id,
    c.zip_code_prefix,
    COALESCE(g.city, c.city) AS city,
    COALESCE(g.state, c.state) AS state,
    COALESCE(g.latitude, 0.0) AS latitude,
    COALESCE(g.longitude, 0.0) AS longitude
FROM customers c
LEFT JOIN geolocation g 
    ON c.zip_code_prefix = g.zip_code_prefix