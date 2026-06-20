output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.zone_id
}

output "app_fqdn" {
  description = "Application fully qualified domain name"
  value       = aws_route53_record.app.fqdn
}

output "health_check_id" {
  description = "Route53 health check ID"
  value       = aws_route53_health_check.main.id
}