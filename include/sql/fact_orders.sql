CREATE TABLE ecommerce_gold.fact_orders
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/fact_orders/'
) AS
SELECT
    i.product_id,
    i.seller_id,
    o.customer_id AS client_id,
    i.order_id,
    i.order_item_id,
    DATE(o.order_purchase_timestamp) AS purchase_date,
    o.order_purchase_timestamp AS purchase_timestamp,
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_value
FROM ecommerce_silver.olist_order_items i
INNER JOIN ecommerce_silver.olist_orders o 
    ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable');