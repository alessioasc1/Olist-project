SELECT
    product_id,
    COALESCE(TRIM(product_category_name), 'N/A') AS product_category_name,
    COALESCE(product_name_lenght, 0)::int AS product_name_length,
    COALESCE(product_description_lenght, 0)::int AS product_description_length,
    COALESCE(product_photos_qty, 0)::int AS product_photos_qty,
    product_weight_g::double AS product_weight_grams,
    product_length_cm::double,
    product_height_cm::double,
    product_width_cm::double,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'PRODUCTS') }}