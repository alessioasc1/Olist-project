SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_at,
    CAST(price AS DOUBLE) AS price,
    CAST(freight_value AS DOUBLE) AS freight_value,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
    FROM {{ source('olist_raw', 'ORDER_ITEMS') }}