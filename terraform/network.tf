data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "etl_sg" {
  name        = "jgs-etl-sg"
  description = "Security Group para servicos de processamento de dados"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "etl-security-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "jgs-rds-sg"
  description = "Security Group para o banco PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  # Regra Única e Segura: Aceita apenas quem tem o crachá do ETL
  ingress {
    description     = "Permite acesso apenas de recursos usando o ETL Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.etl_sg.id] 
  }

  tags = {
    Name        = "rds-security-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Subnet Group do RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "jgs-rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "rds-subnet-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Subnet Group do DMS
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "jgs-dms-subnet-group"
  replication_subnet_group_description = "Subnet group para DMS replication instance"
  subnet_ids                           = data.aws_subnets.default.ids

  tags = {
    Name        = "dms-subnet-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}