resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "datalake_layers" {
    for_each = toset(["landing", "bronze", "silver", "gold"])

    bucket = "jgs-lakehouse-${each.key}-${random_id.bucket_suffix.hex}"

    tags = {
        Name = "${each.key}-zone"
        Environment = "dev"
        ManagedBy = "terraform"
    }
}