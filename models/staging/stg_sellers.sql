SELECT
    seller_id,
    seller_zip_code_prefix AS zip_code_prefix,
    UPPER(TRIM(seller_city)) AS city,
    UPPER(TRIM(seller_state)) AS state,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'SELLERS') }}