from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.providers.amazon.aws.operators.glue_crawler import GlueCrawlerOperator
from airflow.providers.standard.operators.empty import EmptyOperator


tables = [
    "olist_orders",
    "olist_customers",
    "olist_products",
    "olist_geolocation",
    "olist_order_items",
    "olist_order_payments",
    "olist_order_reviews",
    "olist_sellers",
    "product_category_name_translation",
]

default_args = {
    "owner": "jhongs",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="lakehouse_pipeline",
    default_args=default_args,
    description="CDC Pipeline (Olist)",
    schedule="@daily",
    start_date=datetime(2026, 4, 1),
    catchup=False,
    tags=["lakehouse", "aws_glue", "iceberg", "cdc", "olist"],
) as dag:
    start_pipeline = EmptyOperator(task_id="start_pipeline")

    run_bronze_crawler = GlueCrawlerOperator(
        task_id="run_bronze_crawler",
        config={"Name": "jgs-crawler-bronze"},
        wait_for_completion=True,
    )

    process_olist_data = GlueJobOperator.partial(
        task_id="process_olist_data_silver",
        region_name="us-east-1",
        wait_for_completion=True,
        deferrable=True,
    ).expand(
        job_name=[f"jgs-bronze-to-silver-{table}" for table in tables],
    )

    end_pipeline = EmptyOperator(task_id="end_pipeline")

    start_pipeline >> run_bronze_crawler >> process_olist_data >> end_pipeline
