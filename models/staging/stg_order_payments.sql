SELECT
    order_id,
    payment_sequential,
    UPPER(TRIM(payment_type)) AS payment_type,
    CAST(payment_installments AS INT) AS payment_installments,
    CAST(payment_value AS DOUBLE) AS payment_value,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'ORDER_PAYMENTS') }}