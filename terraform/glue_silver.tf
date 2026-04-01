# Banco de dados lógico para a camada Silver
resource "aws_glue_catalog_database" "silver_db" {
  name        = "ecommerce_silver"
  description = "Catálogo de dados da camada Silver (Apache Iceberg)"
}

locals {
  lakehouse_tables = {
    "olist_orders"                          = "order_id"
    "olist_customers"                       = "customer_id"
    "olist_products"                        = "product_id"
    "olist_geolocation"                     = "geolocation_zip_code_prefix"
    "olist_order_items"                     = "order_item_id"
    "olist_order_payments"                  = "payment_sequential"
    "olist_order_reviews"                   = "review_id"
    "olist_sellers"                         = "seller_id"
    "product_category_name_translation"     = "product_category_name"
  }
}

resource "aws_glue_job" "silver_iceberg_jobs" {
  for_each = local.lakehouse_tables

  name     = "jgs-bronze-to-silver-${each.key}"
  role_arn = aws_iam_role.glue_crawler_role.arn
  
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  
  command {
    script_location = "s3://${aws_s3_bucket.athena_results.bucket}/scripts/spark_iceberg_merge.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--datalake-formats"                 = "iceberg"
    "--BRONZE_PATH"                      = "s3://${aws_s3_bucket.datalake_layers["bronze"].bucket}/olist_dms_export/public/${each.key}/"
    "--SILVER_DB"                        = aws_glue_catalog_database.silver_db.name
    "--TABLE_NAME"                       = each.key
    "--PRIMARY_KEY"                      = each.value
    "--conf"                             = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.datalake_layers["silver"].bucket}/iceberg/ --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Table       = each.key
  }
}