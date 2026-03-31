terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configurando o provedor AWS para usar a região que definimos
provider "aws" {
  region = "us-east-1"
  
  # Boas práticas: Tags globais para sabermos de onde vêm os recursos
  default_tags {
    tags = {
      Projeto     = "Framework-Lakehouse"
      Ambiente    = "Dev"
      Gerenciado  = "Terraform"
    }
  }
}