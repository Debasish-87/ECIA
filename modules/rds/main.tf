locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${local.name_prefix}-db-params"
  family = "mysql8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${local.name_prefix}-db-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted

  multi_az = var.multi_az

  backup_retention_period   = 1
  backup_window             = "02:00-03:00"
  maintenance_window        = "sun:04:00-sun:05:00"
  delete_automated_backups  = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-db-final-${random_id.db_suffix.hex}"

  publicly_accessible                 = false
  iam_database_authentication_enabled = true
  copy_tags_to_snapshot               = true
  deletion_protection                 = false

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  enabled_cloudwatch_logs_exports = [
    var.db_engine == "mysql" ? "general" : "postgresql",
    "slowquery",
    "error"
  ]

  performance_insights_enabled = false

  tags = {
    Name = "${local.name_prefix}-db"
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Optional Read Replica
#
# resource "aws_db_instance" "read_replica" {
#   identifier          = "${local.name_prefix}-db-replica"
#   replicate_source_db = aws_db_instance.main.identifier
#   instance_class      = var.db_instance_class
#
#   publicly_accessible = false
#   skip_final_snapshot = true
#   storage_encrypted   = true
#
#   vpc_security_group_ids = [
#     var.db_sg_id
#   ]
# }
