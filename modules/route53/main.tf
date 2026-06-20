locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${local.name_prefix}-zone"
  }
}

data "aws_route53_zone" "existing" {
  count        = var.create_zone ? 0 : 1
  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

resource "aws_route53_record" "app" {
  zone_id = local.zone_id

  name = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"

  type = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  count   = var.environment == "prod" ? 1 : 0
  zone_id = local.zone_id

  name = "www.${var.domain_name}"
  type = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_health_check" "main" {
  fqdn = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"

  port          = 443
  type          = "HTTPS"
  resource_path = "/health"

  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${local.name_prefix}-health-check"
  }
}

resource "aws_cloudwatch_metric_alarm" "route53_health" {
  provider = aws.us_east_1

  alarm_name          = "${local.name_prefix}-route53-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1

  metric_name = "HealthCheckStatus"
  namespace   = "AWS/Route53"

  period    = 60
  statistic = "Minimum"
  threshold = 1

  alarm_description = "Route53 health check failing for ${var.domain_name}"

  alarm_actions = [
    var.sns_topic_arn
  ]

  ok_actions = [
    var.sns_topic_arn
  ]

  dimensions = {
    HealthCheckId = aws_route53_health_check.main.id
  }
}