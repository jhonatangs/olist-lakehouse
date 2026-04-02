from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from airflow.providers.amazon.aws.operators.glue_crawler import GlueCrawlerOperator
from airflow.providers.amazon.aws.operators.athena import AthenaOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
from airflow.models import Variable


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

tables_gold = {
    "gold_obt_sales": "obt.sql",
    "dim_clients": "dim_clients.sql",
    "dim_products": "dim_products.sql",
    "dim_sellers": "dim_sellers.sql",
    "fact_orders": "fact_orders.sql",
    "mart_rfm_summary": "mart_rfm_summary.sql",
}

default_args = {
    "owner": "jhongs",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

script_path = Variable.get("glue_script_path")
athena_results = Variable.get("athena_results_bucket")

with DAG(
    dag_id="lakehouse_pipeline",
    default_args=default_args,
    description="CDC Pipeline (Olist)",
    schedule="@daily",
    start_date=datetime(2026, 4, 1),
    catchup=False,
    template_searchpath=["/usr/local/airflow/include/sql"],
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
        iam_role_name="jgs-framework-glue-role",
        script_location=script_path,
        update_config=False,
        wait_for_completion=True,
        deferrable=True,
    ).expand(
        job_name=[f"jgs-bronze-to-silver-{table}" for table in tables],
    )

    with TaskGroup(group_id="process_gold_layer") as process_gold_layer:
        for table_name, sql_file in tables_gold.items():
            drop_table = AthenaOperator(
                task_id=f"drop_{table_name}",
                query=f"DROP TABLE IF EXISTS ecommerce_gold.{table_name};",
                database="ecommerce_gold",
                output_location=athena_results,
            )

            create_table = AthenaOperator(
                task_id=f"create_{table_name}",
                query=sql_file,
                database="ecommerce_gold",
                output_location=athena_results,
            )

            drop_table >> create_table

    end_pipeline = EmptyOperator(task_id="end_pipeline")

    (
        start_pipeline
        >> run_bronze_crawler
        >> process_olist_data
        >> process_gold_layer
        >> end_pipeline
    )
