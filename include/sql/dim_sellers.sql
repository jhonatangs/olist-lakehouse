CREATE TABLE ecommerce_gold.dim_sellers
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/dim_sellers/'
) AS
SELECT
    seller_id,
    seller_zip_code_prefix AS zip_code,
    seller_city AS city,
    seller_state AS state
FROM ecommerce_silver.olist_sellers;