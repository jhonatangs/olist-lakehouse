CREATE TABLE ecommerce_gold.dim_sellers
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/dim_sellers/'
) AS
SELECT
    s.seller_id,
    s.seller_zip_code_prefix AS zip_code,
    s.seller_city AS city,
    s.seller_state AS state
FROM ecommerce_silver.olist_sellers s;