resource "aws_db_instance" "ecommerce_db" {
  identifier             = "jgs-framework-rds"
  engine                 = "postgres"
  engine_version         = "16.3" 
  instance_class         = "db.t3.micro" 
  allocated_storage      = 20
  
  # Desabilita o auto-crescimento do disco para evitar custos surpresa
  max_allocated_storage  = 0 
  
  # Chamando as variáveis que definimos no variables.tf / terraform.tfvars
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  # O "Segurança" da porta 5432
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # Governança: 100% isolado da internet
  publicly_accessible    = false 
  
  # FinOps: Não queremos pagar por backups quando destruirmos a infraestrutura
  skip_final_snapshot    = true 

  parameter_group_name = aws_db_parameter_group.postgres_cdc.name

  tags = {
    Name        = "ecommerce-database"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_db_parameter_group" "postgres_cdc" {
  name   = "jgs-framework-pg-cdc"
  family = "postgres16"

  # O segredo para o CDC funcionar:
  parameter {
    name  = "rds.logical_replication"
    value = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name        = "pg-cdc-parameter-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}