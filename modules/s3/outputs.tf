output "app_bucket_name" {
  description = "Application S3 bucket name"
  value       = aws_s3_bucket.app.bucket
}

output "app_bucket_arn" {
  description = "Application S3 bucket ARN"
  value       = aws_s3_bucket.app.arn
}

output "logs_bucket_name" {
  description = "Logs S3 bucket name"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "tf_state_bucket" {
  description = "Terraform state bucket name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "tf_lock_table" {
  description = "Terraform state lock DynamoDB table"
  value       = aws_dynamodb_table.terraform_lock.name
}