WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT 
        order_id,
        customer_id
    FROM {{ ref('stg_orders') }}
)

SELECT
    oi.order_id || '-' || oi.order_item_id AS unique_order_item_id,
    oi.order_id,
    COALESCE(oi.product_id, 'N/A') AS product_id, 
    COALESCE(oi.seller_id, 'N/A') AS seller_id,
    oi.shipping_limit_at,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS item_total_value
FROM order_items oi
INNER JOIN orders o 
    ON oi.order_id = o.order_id