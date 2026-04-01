# 1. Role obrigatória para o DMS funcionar dentro de uma VPC
resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role" # O nome tem que ser exatamente este

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })
}

# Anexando a política oficial da AWS a essa Role
resource "aws_iam_role_policy_attachment" "dms_vpc_role_attachment" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# 2. Role obrigatória para o DMS enviar logs de erro (Essencial para debugar falhas depois)
resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name = "dms-cloudwatch-logs-role" #O nome tem que ser exatamente este

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs_role_attachment" {
  role       = aws_iam_role.dms_cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# Criação da Role para o DMS escrever no S3
resource "aws_iam_role" "dms_s3_role" {
  name = "jgs-dms-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })
}

# Dando poder total no S3 apenas para os buckets do nosso Data Lake
resource "aws_iam_role_policy" "dms_s3_policy" {
  name = "jgs-dms-s3-policy"
  role = aws_iam_role.dms_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.datalake_layers["bronze"].arn,
          "${aws_s3_bucket.datalake_layers["bronze"].arn}/*"
        ]
      }
    ]
  })
}