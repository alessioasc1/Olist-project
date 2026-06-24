SELECT
    c.state,
    c.city,
    o.primary_payment_type,
    o.order_id,
    o.order_value,
    o.order_status,
    DATE_TRUNC('month', o.purchase_at) AS payment_month
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} c
    ON o.customer_id_per_transaction = c.customer_id_per_transaction