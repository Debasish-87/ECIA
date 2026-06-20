locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption - ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3Service"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-kms-s3"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption - ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowRDSService"
        Effect = "Allow"

        Principal = {
          Service = "rds.amazonaws.com"
        }

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-kms-rds"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager - ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManager"
        Effect = "Allow"

        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-kms-secrets"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}