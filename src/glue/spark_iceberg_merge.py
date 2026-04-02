import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.window import Window
from pyspark.sql.functions import col, row_number


def check_iceberg_table_exists(spark, database, table_name):
    try:
        spark.sql(f"DESCRIBE TABLE glue_catalog.{database}.{table_name}")
        return True
    except Exception:
        return False


args = getResolvedOptions(
    sys.argv, ["JOB_NAME", "BRONZE_PATH", "SILVER_DB", "TABLE_NAME", "PRIMARY_KEY"]
)
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

bronze_path = args["BRONZE_PATH"]
silver_db = args["SILVER_DB"]
table_name = args["TABLE_NAME"]
pk_string = args["PRIMARY_KEY"]
pk_list = [k.strip() for k in pk_string.split(",")]

print(f"Lendo dados da Bronze em: {bronze_path}")
df_bronze = spark.read.parquet(bronze_path)

# Deduplicação em Memória (Micro-batch)
window_spec = Window.partitionBy(*pk_list).orderBy(col("dms_extracted_at").desc())
df_bronze_clean = (
    df_bronze.withColumn("row_num", row_number().over(window_spec))
    .filter(col("row_num") == 1)
    .drop("row_num")
)
df_bronze_clean.createOrReplaceTempView("bronze_updates")

table_exists = check_iceberg_table_exists(spark, silver_db, table_name)

merge_condition = " AND ".join([f"target.{k} = source.{k}" for k in pk_list])

if not table_exists:
    print("Primeira execução: Criando a tabela Iceberg na camada Silver...")
    df_bronze_clean.writeTo(f"glue_catalog.{silver_db}.{table_name}").tableProperty(
        "format-version", "2"
    ).create()
else:
    print("Tabela Iceberg encontrada: Executando o MERGE INTO (CDC)...")
    spark.sql(f"""
        MERGE INTO glue_catalog.{silver_db}.{table_name} AS target
        USING bronze_updates AS source
        ON {merge_condition}
        WHEN MATCHED AND source.dms_extracted_at > target.dms_extracted_at THEN
            UPDATE SET *
        WHEN NOT MATCHED THEN
            INSERT *
    """)

job.commit()
print("Processamento Iceberg finalizado com sucesso!")
