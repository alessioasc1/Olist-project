SELECT
    o.order_id,
    c.customer_unique_id,
    c.state AS customer_state,
    c.city AS customer_city,
    o.order_status,
    DATE_TRUNC('month', o.purchase_at) AS purchase_month,
    o.order_value,
    o.n_items,
    o.is_late_delivery,
    o.delivery_days,
    o.review_score
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} c
    ON o.customer_id_per_transaction = c.customer_id_per_transaction