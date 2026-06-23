SELECT
    review_id,
    order_id,
    CAST(review_score AS INT) AS review_score,
    TRIM(review_comment_title) AS review_comment_title,
    TRIM(review_comment_message) AS review_comment_message,
    CAST(review_creation_date AS TIMESTAMP) AS review_created_at,
    CAST(review_answer_timestamp AS TIMESTAMP) AS review_answered_at,
    CAST(_loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('olist_raw', 'ORDER_REVIEWS') }}