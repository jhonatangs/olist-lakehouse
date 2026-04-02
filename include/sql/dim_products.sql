CREATE TABLE ecommerce_gold.dim_products
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/dim_products/'
) AS
SELECT
    p.product_id,
    COALESCE(pt.product_category_name_english, p.product_category_name, 'unknown') AS category_name,
    p.product_name_lenght AS name_length,
    p.product_description_lenght AS description_length,
    p.product_photos_qty AS photos_qty,
    p.product_weight_g AS weight_g,
    p.product_length_cm AS length_cm,
    p.product_height_cm AS height_cm,
    p.product_width_cm AS width_cm
FROM ecommerce_silver.olist_products p
LEFT JOIN ecommerce_silver.product_category_name_translation pt 
    ON p.product_category_name = pt.product_category_name;