output "waf_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_log_group" {
  description = "CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf.name
}