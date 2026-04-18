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



ALTER TABLE clean_orders
ADD COLUMN delivery_time_days INT;

UPDATE clean_orders
SET delivery_time_Days = DATEDIFF(order_delivered_customer_date, order_purchase_timestamp);