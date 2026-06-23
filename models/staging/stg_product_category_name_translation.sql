SELECT
    UPPER(TRIM(product_category_name)) AS product_category_name,
    UPPER(TRIM(product_category_name_english)) AS product_category_name_english,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'PRODUCT_CATEGORY_NAME_TRANSLATION') }}