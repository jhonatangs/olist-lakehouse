CREATE TABLE ecommerce_gold.gold_obt_sales
WITH (
    table_type = 'ICEBERG',
    location = '{{ var.value.gold_bucket_path }}/gold_obt_sales/'
) AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    pt.product_category_name_english AS product_category,
    c.customer_city,
    c.customer_state,
    s.seller_city,
    s.seller_state
FROM ecommerce_silver.olist_order_items i
LEFT JOIN ecommerce_silver.olist_orders o ON i.order_id = o.order_id
LEFT JOIN ecommerce_silver.olist_products p ON i.product_id = p.product_id
LEFT JOIN ecommerce_silver.product_category_name_translation pt ON p.product_category_name = pt.product_category_name
LEFT JOIN ecommerce_silver.olist_customers c ON o.customer_id = c.customer_id
LEFT JOIN ecommerce_silver.olist_sellers s ON i.seller_id = s.seller_id;