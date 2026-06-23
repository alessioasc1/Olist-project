SELECT
    customer_id AS customer_id_per_transaction,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code_prefix,
    UPPER(TRIM(customer_city)) AS city,
    UPPER(TRIM(customer_state)) AS state,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'CUSTOMERS') }}