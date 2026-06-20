output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  value = module.vpc.db_subnet_ids
}

output "nat_gateway_ips" {
  value = module.vpc.nat_gateway_ips
}

output "alb_dns_name" {
  value = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  value = module.load_balancer.alb_zone_id
}

output "asg_name" {
  value = module.ec2.asg_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "rds_port" {
  value = module.rds.db_port
}

output "s3_bucket_name" {
  value = module.s3.app_bucket_name
}

output "logs_bucket_name" {
  value = module.s3.logs_bucket_name
}

output "ec2_instance_profile" {
  value = module.iam.ec2_instance_profile_name
}

output "cloudwatch_dashboard_url" {
  value = module.cloudwatch.dashboard_url
}