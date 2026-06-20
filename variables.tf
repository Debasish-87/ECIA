variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-0f58b397bc5c1f2e8"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "alert_email" {
  type    = string
  default = "alerts@example.com"
}