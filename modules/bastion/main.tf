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

data "aws_region" "current" {}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.nano"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  iam_instance_profile        = var.iam_instance_profile
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent

    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

    systemctl restart sshd
    EOF
  )

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "${local.name_prefix}-bastion-eip"
  }
}

resource "aws_cloudwatch_event_rule" "stop_bastion" {
  name                = "${local.name_prefix}-stop-bastion"
  description         = "Stop bastion at midnight UTC"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop_bastion" {
  rule     = aws_cloudwatch_event_rule.stop_bastion.name
  arn      = "arn:aws:ssm:${data.aws_region.current.name}::automation-definition/AWS-StopEC2Instance"
  role_arn = aws_iam_role.events.arn

  input = jsonencode({
    InstanceId           = [aws_instance.bastion.id]
    AutomationAssumeRole = [aws_iam_role.events.arn]
  })
}

resource "aws_iam_role" "events" {
  name = "${local.name_prefix}-bastion-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "events" {
  role = aws_iam_role.events.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:StartAutomationExecution",
          "ec2:StopInstances"
        ]

        Resource = "*"
      }
    ]
  })
}