create database customer360;
use customer360;

create table stg_customers(
	customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

CREATE TABLE stg_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE stg_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

CREATE TABLE stg_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE stg_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);


CREATE TABLE stg_order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

SELECT COUNT(*) FROM stg_customers;
SELECT COUNT(*) FROM stg_orders;
SELECT COUNT(*) FROM stg_order_items;
SELECT COUNT(*) FROM stg_products;
SELECT COUNT(*) FROM stg_sellers;
SELECT COUNT(*) FROM stg_order_payments;
SELECT * FROM stg_orders LIMIT 10;


CREATE TABLE clean_customers AS
SELECT DISTINCT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers
WHERE customer_id IS NOT NULL;

CREATE TABLE clean_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM stg_orders
WHERE order_id IS NOT NULL
AND order_purchase_timestamp IS NOT NULL;

CREATE TABLE clean_order_items AS
SELECT DISTINCT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM stg_order_items
WHERE order_id IS NOT NULL
AND product_id IS NOT NULL;

CREATE TABLE clean_products AS
SELECT DISTINCT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM stg_products
WHERE product_id IS NOT NULL;

CREATE TABLE clean_sellers AS
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers
WHERE seller_id IS NOT NULL;

CREATE TABLE clean_order_payments AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE order_id IS NOT NULL;

SELECT COUNT(*)
FROM clean_orders o
LEFT JOIN clean_customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


select count(*)
from clean_order_items oi left join clean_orders o
on oi.order_id=o.order_id
where o.order_id is null;

SELECT order_id, order_item_id, COUNT(*)
FROM clean_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


SELECT COUNT(*)
FROM clean_order_items oi
LEFT JOIN clean_products p
ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*)
FROM clean_order_items oi
LEFT JOIN clean_sellers s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

CREATE TABLE clean_order_items_v2 AS
SELECT oi.*
FROM clean_order_items oi
JOIN clean_orders o
ON oi.order_id = o.order_id;

DROP TABLE clean_order_items;
RENAME TABLE clean_order_items_v2 TO clean_order_items;

SELECT COUNT(*)
FROM clean_order_items oi
LEFT JOIN clean_orders o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


CREATE TABLE dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
FROM clean_customers;

CREATE TABLE dim_products AS
SELECT
    product_id,
    product_category_name
FROM clean_products;

CREATE TABLE dim_sellers AS
SELECT
    seller_id,
    seller_city,
    seller_state
FROM clean_sellers;

CREATE TABLE fact_orders AS
SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,

    o.order_purchase_timestamp,
    o.order_delivered_customer_date,

    oi.price,
    oi.freight_value,

    (oi.price + oi.freight_value) AS order_value,

    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_time_days

FROM clean_order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id;

SELECT COUNT(*)
FROM fact_orders
WHERE customer_id IS NULL;

SELECT COUNT(*) FROM fact_orders;

CREATE INDEX idx_fact_customer ON fact_orders(customer_id);
CREATE INDEX idx_fact_product ON fact_orders(product_id);
CREATE INDEX idx_fact_seller ON fact_orders(seller_id);
CREATE INDEX idx_fact_order ON fact_orders(order_id);

-- customer lifetime value(CLV)

CREATE VIEW customer_lifetime_value AS
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(order_value) AS total_revenue,
    AVG(order_value) AS avg_order_value
FROM fact_orders
GROUP BY customer_id;

-- monthly revenue

CREATE VIEW monthly_revenue AS
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    SUM(order_value) AS revenue
FROM fact_orders
GROUP BY month
ORDER BY month;

-- repeat purchase rate
CREATE VIEW repeat_purchase_rate AS
SELECT
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) * 1.0 /
    COUNT(DISTINCT customer_id) AS repeat_rate
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_id
) t;

-- average order values
CREATE VIEW avg_order_value AS
SELECT
    SUM(order_value) / COUNT(DISTINCT order_id) AS avg_order_value
FROM fact_orders;

-- RFM segmentation

CREATE VIEW customer_segments_rfm AS
SELECT
    customer_id,

    MAX(order_purchase_timestamp) AS last_purchase,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(order_value) AS monetary

FROM fact_orders
GROUP BY customer_id;


-- testing views
SELECT * FROM customer_lifetime_value LIMIT 5;
SELECT * FROM monthly_revenue LIMIT 5;

-- cohort analysis(behaviour over time)

CREATE VIEW customer_first_purchase AS
SELECT
    customer_id,
    MIN(order_purchase_timestamp) AS first_purchase_date
FROM fact_orders
GROUP BY customer_id;

-- return in which monthh specific customers purchase happens
CREATE VIEW customer_cohorts AS
SELECT
    customer_id,
    DATE_FORMAT(first_purchase_date, '%Y-%m') AS cohort_month
FROM customer_first_purchase;

-- track activity over time give active cutsomers list and their active purchases 
CREATE VIEW cohort_activity AS
SELECT
    c.cohort_month,
    DATE_FORMAT(f.order_purchase_timestamp, '%Y-%m') AS activity_month,
    COUNT(DISTINCT f.customer_id) AS active_customers
FROM fact_orders f
JOIN customer_cohorts c
ON f.customer_id = c.customer_id
GROUP BY c.cohort_month, activity_month;

--  return This query builds a Cohort Retention Analysis, which is the gold standard for measuring how well you keep customers over time. It compares how many customers started in a specific month (the cohort) vs. how many of them came back in following months.
CREATE VIEW cohort_retention AS
SELECT
    cohort_month,
    activity_month,
    active_customers,

    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS cohort_size,

    active_customers * 1.0 /
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY activity_month) AS retention_rate

FROM cohort_activity;


-- churn logic we define churn logic as No purchase in last 90 days

CREATE view customer_churn AS
SELECT
    customer_id,
    MAX(order_purchase_timestamp) AS last_purchase_date,

    CASE 
        WHEN DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM fact_orders),
            MAX(order_purchase_timestamp)
        ) > 90 THEN 1
        ELSE 0
    END AS churn_flag

FROM fact_orders
GROUP BY customer_id;

-- customer360 view

CREATE VIEW customer_360_view AS
SELECT
    c.customer_id,

    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.order_value) AS total_revenue,
    MAX(f.order_purchase_timestamp) AS last_purchase_date,

    ch.churn_flag,

    r.frequency,
    r.monetary

FROM dim_customers c
LEFT JOIN fact_orders f ON c.customer_id = f.customer_id
LEFT JOIN customer_churn ch ON c.customer_id = ch.customer_id
LEFT JOIN customer_segments_rfm r ON c.customer_id = r.customer_id

GROUP BY c.customer_id, ch.churn_flag, r.frequency, r.monetary;

SELECT * FROM customer_360_view LIMIT 10;

DROP VIEW customer_churn;
DROP VIEW customer_360_view;