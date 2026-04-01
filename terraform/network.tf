# terraform/network.tf

# 1. Buscando a VPC padrão (Rede) que já existe na sua conta
data "aws_vpc" "default" {
  default = true
}

# 2. O "Crachá" para os nossos serviços de ETL (DMS, Lambda, Glue)
resource "aws_security_group" "etl_sg" {
  name        = "jgs-framework-etl-sg"
  description = "Security Group para servicos de processamento de dados"
  vpc_id      = data.aws_vpc.default.id

  # Regra de Saída (Egress): O ETL pode acessar a internet (ex: baixar bibliotecas)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa "todos os protocolos"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "etl-security-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# 3. A "Porta de Entrada" do nosso Banco de Dados (RDS)
resource "aws_security_group" "rds_sg" {
  name        = "jgs-framework-rds-sg"
  description = "Security Group para o banco PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  # Regra de Entrada (Ingress): QUEM PODE ENTRAR NO BANCO?
  ingress {
    description     = "Permite acesso apenas de recursos usando o ETL Security Group"
    from_port       = 5432 # Porta padrão do PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    
    # Em vez de um IP, passamos o ID do Security Group do ETL
    security_groups = [aws_security_group.etl_sg.id] 
  }

  tags = {
    Name        = "rds-security-group"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}