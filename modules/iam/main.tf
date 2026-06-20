locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ec2_custom" {
  name = "${local.name_prefix}-ec2-custom-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3AppBucketAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-*/*"
        ]
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "arn:aws:secretsmanager:*:*:secret:${local.name_prefix}/*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "s3.*.amazonaws.com",
              "secretsmanager.*.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "EC2DescribeSelf"
        Effect = "Allow"

        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_secretsmanager_secret" "db_creds" {
  name                    = "${local.name_prefix}/db/credentials"
  description             = "RDS master credentials for ${local.name_prefix}"
  recovery_window_in_days = 7

  tags = {
    Name = "${local.name_prefix}-db-secret"
  }
}

resource "aws_iam_role" "deploy" {
  name = "${local.name_prefix}-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
      {
        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-deploy-role"
  }
}

resource "aws_iam_role_policy" "deploy_policy" {
  name = "${local.name_prefix}-deploy-policy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EC2AndASG"
        Effect = "Allow"

        Action = [
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*"
        ]

        Resource = "*"
      },
      {
        Sid    = "S3Deploy"
        Effect = "Allow"

        Action = [
          "s3:*"
        ]

        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:*",
          "cloudwatch:*"
        ]

        Resource = "*"
      }
    ]
  })
}