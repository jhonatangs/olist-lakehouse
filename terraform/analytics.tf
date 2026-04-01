# O Athena precisa de um lugar para salvar o histórico de queries
resource "aws_s3_bucket" "athena_results" {
  bucket = "jgs-lakehouse-athena-results-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "athena-query-results"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# O Banco de Dados Lógico (Catálogo do AWS Glue)
resource "aws_glue_catalog_database" "bronze_db" {
  name        = "ecommerce_bronze"
  description = "Catálogo de dados da camada Bronze do Lakehouse"
}

# O Crachá do Robô
resource "aws_iam_role" "glue_crawler_role" {
  name = "jgs-framework-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "glue.amazonaws.com" }
      }
    ]
  })
}

# Permissões padrão do Glue
resource "aws_iam_role_policy_attachment" "glue_service_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Permissão explícita para o Glue acessar o S3
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "jgs-glue-s3-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.datalake_layers["bronze"].arn,
          "${aws_s3_bucket.datalake_layers["bronze"].arn}/*",
          aws_s3_bucket.datalake_layers["silver"].arn,
          "${aws_s3_bucket.datalake_layers["silver"].arn}/*",
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
      }
    ]
  })
}

# O Robô: AWS Glue Crawler
resource "aws_glue_crawler" "bronze_crawler" {
  name          = "jgs-crawler-bronze"
  database_name = aws_glue_catalog_database.bronze_db.name
  role          = aws_iam_role.glue_crawler_role.arn

  # Apontando o Crawler para a pasta onde o DMS jogou os arquivos
  s3_target {
    path = "s3://${aws_s3_bucket.datalake_layers["bronze"].bucket}/olist_dms_export/public/"
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Ambiente de Consulta: Workgroup do Amazon Athena
resource "aws_athena_workgroup" "analytics_wg" {
  name = "jgs_analytics_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/output/"
    }
  }
}