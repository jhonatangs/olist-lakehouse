# Banco de dados lógico para a camada Gold (Analytics)
resource "aws_glue_catalog_database" "gold_db" {
  name        = "ecommerce_gold"
  description = "Catálogo de dados da camada Gold - Modelagem de Negócio e Agregações"  
  parameters = {
    "classification" = "lakehouse"
    "layer"          = "gold"
  }
}