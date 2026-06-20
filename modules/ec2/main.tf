locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

yum update -y
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60
  },
  "metrics": {
    "namespace": "${local.name_prefix}/EC2",
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/*.log",
            "log_group_name": "/app/${local.name_prefix}",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWCONFIG

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "S3_BUCKET=${var.s3_bucket_name}" >> /etc/environment
echo "Instance provisioned by Terraform at $(date)" > /tmp/bootstrap.log
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name_prefix}-app-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${local.name_prefix}-app-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  default_instance_warmup = 300

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance"
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = {
      Name        = "${local.name_prefix}-app"
      Environment = var.environment
      Project     = var.project_name
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_autoscaling_policy" "cpu_scale_out" {
  name                   = "${local.name_prefix}-scale-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}

resource "aws_autoscaling_schedule" "scale_down_night" {
  scheduled_action_name  = "${local.name_prefix}-scale-down-night"
  autoscaling_group_name = aws_autoscaling_group.app.name

  recurrence = "0 20 * * MON-FRI"

  desired_capacity = var.min_size
  min_size         = var.min_size
  max_size         = var.max_size
}

resource "aws_autoscaling_schedule" "scale_up_morning" {
  scheduled_action_name  = "${local.name_prefix}-scale-up-morning"
  autoscaling_group_name = aws_autoscaling_group.app.name

  recurrence = "0 7 * * MON-FRI"

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
}