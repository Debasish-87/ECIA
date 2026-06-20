output "alb_sg_id" {
  description = "Application Load Balancer security group ID"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}

output "bastion_sg_id" {
  description = "Bastion host security group ID"
  value       = aws_security_group.bastion.id
}