CREATE TABLE ecommerce_gold.mart_rfm_summary
WITH (
    table_type = 'ICEBERG',
    is_external = false,
    location = '{{ var.value.gold_bucket_path }}/mart_rfm_summary/'
) AS
SELECT
    c.client_unique_id,
    -- Recência (Recency): Dias desde a última compra até "hoje" (considerando a última data de compra na base como "hoje")
    DATE_DIFF('day', MAX(f.purchase_date), (SELECT MAX(purchase_date) FROM ecommerce_gold.fact_orders)) AS recency_days,
    -- Frequência (Frequency): Total de pedidos únicos
    COUNT(DISTINCT f.order_id) AS frequency,
    -- Monetário (Monetary): Soma de tudo que gastou
    ROUND(SUM(f.total_value), 2) AS monetary_value
FROM ecommerce_gold.fact_orders f
JOIN ecommerce_gold.dim_clients c ON f.client_id = c.client_id
GROUP BY c.client_unique_id;