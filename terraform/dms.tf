# 1. A Instância de Replicação (O Servidor do DMS)
resource "aws_dms_replication_instance" "dms_engine" {
  replication_instance_id    = "jgs-framework-dms-instance"
  replication_instance_class = "dms.t3.small"
  allocated_storage          = 20
  
  # O DMS precisa estar na mesma rede (VPC) que o RDS e a EC2
  vpc_security_group_ids     = [aws_security_group.etl_sg.id]
  
  # Para economizar, não precisamos de Multi-AZ em ambiente de Dev
  multi_az                   = false
  publicly_accessible        = true

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc_role_attachment,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs_role_attachment
  ]

  tags = {
    Name        = "dms-replication-engine"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_dms_endpoint" "source_postgres" {
  endpoint_id                 = "jgs-source-postgres"
  endpoint_type               = "source"
  engine_name                 = "postgres"
  
  # Pegamos os dados dinamicamente do recurso do banco que já criamos
  server_name                 = aws_db_instance.ecommerce_db.address
  port                        = aws_db_instance.ecommerce_db.port
  database_name               = aws_db_instance.ecommerce_db.db_name
  username                    = aws_db_instance.ecommerce_db.username
  
  # Senha vinda do seu arquivo terraform.tfvars
  password                    = var.db_password 

  tags = {
    Name        = "dms-source-endpoint"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_dms_endpoint" "target_s3" {
  endpoint_id   = "jgs-target-s3-bronze"
  endpoint_type = "target"
  engine_name   = "s3"

  s3_settings {
    bucket_name             = aws_s3_bucket.datalake_layers["bronze"].bucket
    bucket_folder           = "olist_dms_export" # Uma subpasta para organizar
    data_format             = "parquet"          # Formato colunar otimizado
    compression_type        = "GZIP"             # Economiza muito espaço na nuvem
    timestamp_column_name   = "dms_extracted_at"
    add_column_name         = true
    service_access_role_arn = aws_iam_role.dms_s3_role.arn         
  }

  tags = {
    Name        = "dms-target-endpoint"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_dms_replication_task" "olist_migration" {
  replication_task_id      = "jgs-task-olist-to-s3"
  
  # Aqui juntamos as 3 peças anteriores!
  replication_instance_arn = aws_dms_replication_instance.dms_engine.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source_postgres.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target_s3.endpoint_arn

  # A Decisão de Ouro: Carga inicial (histórico) + Replicação Contínua (futuro)
  migration_type           = "full-load-and-cdc"

  # JSON obrigatório dizendo QUAIS tabelas queremos copiar
  # O "%" significa "copie todas as tabelas do schema public"
  table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = "public"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })

  tags = {
    Name        = "dms-replication-task"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}