variable "project_name" {
  description = "Project name used as resource prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to associate with WAF"
  type        = string
}