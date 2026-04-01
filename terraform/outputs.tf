# terraform/outputs.tf

# 1. URL de conexão do Banco de Dados (Fundamental para o DMS e para o nosso acesso)
output "rds_endpoint" {
  description = "O endereço (URL) para ligar à base de dados PostgreSQL"
  value       = aws_db_instance.ecommerce_db.endpoint
}

# 2. ID da Instância EC2 (Necessário para o acesso via AWS Console/SSM)
output "bastion_instance_id" {
  description = "O ID da máquina de salto (Bastion Host)"
  value       = aws_instance.bastion.id
}

# 3. Nomes dos Buckets do Data Lake (Útil para configurar o Airflow depois)
output "s3_bucket_names" {
  description = "Lista dos nomes reais dos buckets criados no S3"
  value       = { for k, v in aws_s3_bucket.datalake_layers : k => v.bucket }
}

output "glue_scripts_bucket" {
  description = "Nome do bucket onde o GitHub Actions deve jogar os scripts"
  value       = aws_s3_bucket.athena_results.bucket
}