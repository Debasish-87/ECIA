output "s3_kms_key_arn" {
  description = "ARN of the S3 KMS key"
  value       = aws_kms_key.s3.arn
}

output "s3_kms_key_id" {
  description = "ID of the S3 KMS key"
  value       = aws_kms_key.s3.key_id
}

output "rds_kms_key_arn" {
  description = "ARN of the RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "rds_kms_key_id" {
  description = "ID of the RDS KMS key"
  value       = aws_kms_key.rds.key_id
}

output "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager KMS key"
  value       = aws_kms_key.secrets.arn
}

output "secrets_kms_key_id" {
  description = "ID of the Secrets Manager KMS key"
  value       = aws_kms_key.secrets.key_id
}