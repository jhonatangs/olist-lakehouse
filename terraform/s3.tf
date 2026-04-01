locals {
    layers = toset(["landing", "bronze", "silver", "gold"])
}

resource "aws_s3_bucket" "datalake_layers" {
    for_each = local.layers

    bucket = "jgs-framework-lakehouse-${each.key}"

    tags = {
        Name = "${each.key}-zone"
        Environment = "dev"
        ManagedBy = "terraform"
    }
}