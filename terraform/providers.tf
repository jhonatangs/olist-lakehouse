terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configurando o provedor AWS para usar a região definida
provider "aws" {
  region = "us-east-1"
  
  # Tags globais para saber de onde vêm os recursos
  default_tags {
    tags = {
      Name        = "Lakehouse"
      Environment = "Dev"
      ManagedBy   = "Terraform"
    }
  }
}