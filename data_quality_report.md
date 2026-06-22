# Data Quality Report
## Dimension 0: Sanity Check 

* Findings: Raw data ingestion is verified with no record loss across all 9 tables. GEOLOCATION represents the largest data volume (>1M rows), while core transactional tables (ORDERS, CUSTOMERS, ORDER_ITEMS) scale consistently around the expected ~100k rows benchmark.

SELECT 'ORDERS' AS table_name, COUNT(*) AS row_count FROM ORDERS
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS
UNION ALL SELECT 'ORDER_PAYMENTS', COUNT(*) FROM ORDER_PAYMENTS
UNION ALL SELECT 'ORDER_REVIEWS', COUNT(*) FROM ORDER_REVIEWS
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL SELECT 'SELLERS', COUNT(*) FROM SELLERS
UNION ALL SELECT 'GEOLOCATION', COUNT(*) FROM GEOLOCATION
UNION ALL SELECT 'PRODUCT_CATEGORY_NAME_TRANSLATION', COUNT(*) FROM PRODUCT_CATEGORY_NAME_TRANSLATION
ORDER BY row_count DESC;

---

## Dimension 1: Completeness

* Findings: Out of ~96k delivered orders, 24 rows lack timestamps. While missing dates are expected for non-delivered statuses based on order lifecycles, these 24 records confirm tracking omissions within the finalized orders group.

SELECT
  COUNT(*)                                          AS total,
  COUNT(*) - COUNT(order_approved_at)               AS missing_approved,
  COUNT(*) - COUNT(order_delivered_customer_date)   AS missing_delivered,
  COUNT(*) - COUNT(order_delivered_carrier_date)    AS missing_shipped
FROM ORDERS
WHERE order_status = 'delivered';

* Findings: Out of 32k products, 610 rows lack a category name, while physical attributes like weight miss only 2 values. Missing categories represent catalog gaps that require handling during staging.

SELECT
  COUNT(*)                                AS total,
  COUNT(*) - COUNT(product_category_name) AS missing_category,
  COUNT(*) - COUNT(product_weight_g)      AS missing_weight
FROM PRODUCTS;

* Findings: The majority of customer reviews lack text entries, with over 85% missing a title and over 50% missing a message body. These blanks reflect voluntary user behavior rather than data pipeline errors.

SELECT
  COUNT(*)                                   AS total,
  COUNT(*) - COUNT(review_comment_title)     AS missing_title,
  COUNT(*) - COUNT(review_comment_message)   AS missing_message
FROM ORDER_REVIEWS;

---

## Dimension 2: Uniqueness

* Findings: The GEOLOCATION table contains over 1M total rows against only ~19k unique zip codes, averaging multiple records per prefix with minor coordinate variations. This replication requires spatial aggregation to a single point per zip code prefix during staging.

SELECT
  COUNT(*)                                                AS total_rows,
  COUNT(DISTINCT geolocation_zip_code_prefix)             AS unique_zips,
  COUNT(*) / COUNT(DISTINCT geolocation_zip_code_prefix)  AS avg_rows_per_zip
FROM GEOLOCATION;

* Findings: Ranking the top zip code prefixes confirms which urban areas generate the highest frequency of repeated entries in the dataset.

SELECT geolocation_zip_code_prefix, COUNT(*) AS repeats
FROM GEOLOCATION GROUP BY geolocation_zip_code_prefix
ORDER BY repeats DESC LIMIT 10;

* Findings: The primary key review_id is not unique, with identical IDs appearing up to 3 times. This indicates duplicate survey submissions.

SELECT review_id, COUNT(*) AS times
FROM ORDER_REVIEWS GROUP BY review_id
HAVING COUNT(*) > 1 ORDER BY times DESC LIMIT 10;

---

## Dimension 3: Granularity

* Findings: The total row count matches the number of distinct customer_id records (~99k), confirming that customer_id is unique per transaction. However, customer_unique_id reveals fewer distinct values (~96k), establishing that single consumers generate multiple transaction keys over time.

SELECT
  COUNT(*)                            AS row_count,
  COUNT(DISTINCT customer_id)         AS customer_id_distinct,
  COUNT(DISTINCT customer_unique_id)  AS real_customers
FROM CUSTOMERS;

* Findings: Grouping items by order ID shows that single transactions frequently contain multiple product lines. This multi-line structure requires proper handling to prevent artificial inflation of transaction counts during aggregation.

SELECT order_id, COUNT(*) AS lines
FROM ORDER_ITEMS GROUP BY order_id ORDER BY lines DESC LIMIT 10;

* Findings: Orders can map to multiple entries within the payment table. This indicates that a single transaction can be split across multiple installments or distinct payment methods.

SELECT order_id, COUNT(*) AS payments
FROM ORDER_PAYMENTS GROUP BY order_id
HAVING COUNT(*) > 1 ORDER BY payments DESC LIMIT 10;

---

## Dimension 4: Validity

* Findings: Outliers exist in financial data, including transaction records with a payment type categorized as not_defined and payment rows containing 0 installments. These invalid business states require data cleaning rules during transformation.

SELECT payment_type, COUNT(*) AS row_count
FROM ORDER_PAYMENTS GROUP BY payment_type ORDER BY row_count DESC;

SELECT payment_installments, COUNT(*) AS row_count
FROM ORDER_PAYMENTS GROUP BY payment_installments
ORDER BY TRY_TO_NUMBER(payment_installments);

* Findings: Filtering the geospatial dataset using standard bounding box limits for Brazil (Latitude [-34, 5], Longitude [-74, -34]) identifies rows mapped entirely outside the country's territory. These coordinates represent data entry errors.

SELECT COUNT(*) AS coords_outside_brazil
FROM GEOLOCATION
WHERE TRY_TO_DOUBLE(geolocation_lat) NOT BETWEEN -34 AND 5
   OR TRY_TO_DOUBLE(geolocation_lng) NOT BETWEEN -74 AND -34;

---

## Dimension 5: Referential Integrity

* Findings: A LEFT JOIN between products and their English translation schema isolates distinct category names present in the catalog but missing from the dictionary. Standard inner joins on these values would cause silent data loss during reporting.

SELECT DISTINCT p.product_category_name
FROM PRODUCTS p
LEFT JOIN PRODUCT_CATEGORY_NAME_TRANSLATION t
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;