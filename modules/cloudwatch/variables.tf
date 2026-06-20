variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "tg_arn_suffix" {
  type = string
}

variable "rds_identifier" {
  type = string
}

variable "sns_email" {
  type    = string
  default = "alerts@example.com"
}

variable "aws_region" {
  type = string
}

