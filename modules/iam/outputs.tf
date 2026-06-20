output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN"
  value       = aws_iam_instance_profile.ec2.arn
}

output "deploy_role_arn" {
  description = "Deployment IAM role ARN"
  value       = aws_iam_role.deploy.arn
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN for database credentials"
  value       = aws_secretsmanager_secret.db_creds.arn
}