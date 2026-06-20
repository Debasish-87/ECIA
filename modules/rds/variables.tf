variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
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
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "storage_encrypted" {
  type    = bool
  default = true
}