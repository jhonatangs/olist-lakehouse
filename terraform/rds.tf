resource "aws_db_parameter_group" "postgres_cdc" {
  name   = "jgs-pg-cdc"
  family = "postgres16"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name        = "pg-cdc-parameter-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_db_instance" "ecommerce_db" {
  identifier             = "jgs-rds"
  engine                 = "postgres"
  engine_version         = "16.3" 
  instance_class         = "db.t3.micro" 
  allocated_storage      = 20
  max_allocated_storage  = 0 
  
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  # Forçando o RDS nas mesmas sub-redes do projeto
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false 
  skip_final_snapshot    = true 
  parameter_group_name   = aws_db_parameter_group.postgres_cdc.name

  tags = {
    Name        = "ecommerce-database"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}