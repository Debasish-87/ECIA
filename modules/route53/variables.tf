variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "create_zone" {
  type    = bool
  default = false
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}