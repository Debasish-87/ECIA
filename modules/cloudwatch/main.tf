locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts"
  }
}


resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-asg-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ASG average CPU >= 80% for 4 min"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_low" {
  alarm_name          = "${local.name_prefix}-asg-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "ASG average CPU <= 10% — possible idle infra"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returning >10 5xx errors per minute"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "${local.name_prefix}-target-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.tg_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "At least one target is unhealthy"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.tg_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${local.name_prefix}-alb-latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 2
  alarm_description   = "p99 latency >= 2s"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.tg_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name_prefix}-rds-low-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120
  alarm_description   = "RDS free storage <= 5 GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 100
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${local.name_prefix}-rds-read-latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 0.1
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}




resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({

    widgets = [
      {
        type = "metric"

        x      = 0
        y      = 0
        width  = 8
        height = 6

        properties = {
          title   = "ASG CPU Utilization"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.asg_name,
              {
                stat   = "Average"
                period = 60
              }
            ]
          ]

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },

      {
        type = "metric"

        x      = 8
        y      = 0
        width  = 8
        height = 6

        properties = {
          title  = "ASG Instance Count"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.asg_name,
              {
                stat   = "Average"
                period = 60
              }
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 16
        y      = 0
        width  = 8
        height = 6

        properties = {
          title  = "ASG Network I/O"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/EC2",
              "NetworkIn",
              "AutoScalingGroupName",
              var.asg_name,
              {
                stat   = "Sum"
                period = 60
                label  = "NetworkIn"
              }
            ],
            [
              "AWS/EC2",
              "NetworkOut",
              "AutoScalingGroupName",
              var.asg_name,
              {
                stat   = "Sum"
                period = 60
                label  = "NetworkOut"
              }
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.alb_arn_suffix,
              {
                stat   = "Sum"
                period = 60
              }
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 8
        y      = 6
        width  = 8
        height = 6

        properties = {
          title  = "ALB HTTP Errors"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_4XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          title  = "ALB Latency"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 0
        y      = 12
        width  = 8
        height = 6

        properties = {
          title  = "RDS CPU"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              var.rds_identifier
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 8
        y      = 12
        width  = 8
        height = 6

        properties = {
          title  = "RDS Connections"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              var.rds_identifier
            ]
          ]
        }
      },

      {
        type = "metric"

        x      = 16
        y      = 12
        width  = 8
        height = 6

        properties = {
          title  = "RDS Free Storage"
          view   = "timeSeries"
          region = var.aws_region

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              var.rds_identifier
            ]
          ]
        }
      },

      {
        type = "alarm"

        x      = 0
        y      = 18
        width  = 24
        height = 4

        properties = {
          title = "Infrastructure Alarm Status"

          alarms = [
            aws_cloudwatch_metric_alarm.asg_cpu_high.arn,
            aws_cloudwatch_metric_alarm.alb_5xx.arn,
            aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn,
            aws_cloudwatch_metric_alarm.alb_latency.arn,
            aws_cloudwatch_metric_alarm.rds_cpu.arn,
            aws_cloudwatch_metric_alarm.rds_storage.arn,
            aws_cloudwatch_metric_alarm.rds_connections.arn
          ]
        }
      }
    ]
  })
}

