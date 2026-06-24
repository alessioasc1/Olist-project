WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_items_aggregated AS (
    SELECT
        order_id,
        MAX(order_item_id) AS n_items,
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight,
        SUM(price + freight_value) AS order_value
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

order_payments_aggregated AS (
    SELECT
        order_id,
        MAX(payment_installments) AS payment_installments_max,
        MAX_BY(payment_type, payment_value) AS primary_payment_type
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

review_score_aggregated AS (
    SELECT 
        order_id,
        avg(review_score) AS review_score
    FROM {{ ref('stg_order_reviews') }}
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id AS customer_id_per_transaction,
    o.order_status,
    o.purchase_at,
    o.approved_at,
    o.delivered_customer_at,
    o.estimated_delivery_at,
    COALESCE(i.order_value, 0.0) AS order_value,
    COALESCE(i.total_price, 0.0) AS total_price,
    COALESCE(i.total_freight, 0.0) AS total_freight,
    i.n_items,
    r.review_score,
    COALESCE(p.payment_installments_max::VARCHAR, 'N/A') AS payment_installments_max,
    COALESCE(p.primary_payment_type, 'N/A') AS primary_payment_type,
    DATEDIFF('day', o.purchase_at, o.delivered_customer_at) AS delivery_days,
    CASE 
        WHEN o.delivered_customer_at > o.estimated_delivery_at THEN 1 
        ELSE 0 
    END AS is_late_delivery
FROM orders o
LEFT JOIN order_items_aggregated i ON o.order_id = i.order_id
LEFT JOIN order_payments_aggregated p ON o.order_id = p.order_id
LEFT JOIN review_score_aggregated r ON o.order_id = r.order_id