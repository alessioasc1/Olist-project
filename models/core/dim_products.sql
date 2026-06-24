WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

translations AS (
    SELECT * FROM {{ ref('stg_product_category_name_translation') }}
)

SELECT
    p.product_id,
    p.product_category_name AS product_category_name_pt,
    COALESCE(t.product_category_name_english, 'N/A') AS product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_grams,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p
LEFT JOIN translations t 
    ON p.product_category_name = t.product_category_name