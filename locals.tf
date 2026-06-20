locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Region      = var.aws_region
  }

  az_count = length(var.availability_zones)

  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
}