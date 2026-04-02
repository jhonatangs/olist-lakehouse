CREATE TABLE ecommerce_gold.dim_clients
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/dim_clients/'
) AS
SELECT
    c.customer_id AS client_id,
    c.customer_unique_id AS client_unique_id,
    c.customer_zip_code_prefix AS zip_code,
    c.customer_city AS city,
    c.customer_state AS state
FROM ecommerce_silver.olist_customers c;