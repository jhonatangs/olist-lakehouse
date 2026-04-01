import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job


args = getResolvedOptions(
    sys.argv, ["JOB_NAME", "BRONZE_PATH", "SILVER_DB", "TABLE_NAME"]
)
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

bronze_path = args["BRONZE_PATH"]
silver_db = args["SILVER_DB"]
table_name = args["TABLE_NAME"]

print(f"Lendo dados da Bronze em: {bronze_path}")
df_bronze = spark.read.parquet(bronze_path)

df_bronze.createOrReplaceTempView("bronze_updates")

table_exists = spark.catalog.tableExists(f"glue_catalog.{silver_db}.{table_name}")

if not table_exists:
    print("Primeira execução: Criando a tabela Iceberg na camada Silver...")
    df_bronze.writeTo(f"glue_catalog.{silver_db}.{table_name}").tableProperty(
        "format-version", "2"
    ).create()
else:
    print("Tabela Iceberg encontrada: Executando o MERGE INTO (CDC)...")
    spark.sql(f"""
        MERGE INTO glue_catalog.{silver_db}.{table_name} AS target
        USING bronze_updates AS source
        ON target.order_id = source.order_id
        WHEN MATCHED AND source.dms_extracted_at > target.dms_extracted_at THEN
            UPDATE SET *
        WHEN NOT MATCHED THEN
            INSERT *
    """)

job.commit()
print("Processamento Iceberg finalizado com sucesso!")
