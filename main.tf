provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_flow_logs     = var.enable_flow_logs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

module "load_balancer" {
  source = "./modules/load-balancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  certificate_arn   = var.certificate_arn
}

module "ec2" {
  source = "./modules/ec2"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  app_sg_id            = module.security_groups.app_sg_id
  instance_type        = var.ec2_instance_type
  ami_id               = var.ami_id
  key_name             = var.key_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  desired_capacity     = var.asg_desired_capacity
  target_group_arn     = module.load_balancer.target_group_arn
  s3_bucket_name       = module.s3.app_bucket_name
}

module "rds" {
  source = "./modules/rds"

  project_name      = var.project_name
  environment       = var.environment
  db_subnet_ids     = module.vpc.db_subnet_ids
  db_sg_id          = module.security_groups.db_sg_id
  db_engine         = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  multi_az          = var.db_multi_az
  storage_encrypted = true
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name   = var.project_name
  environment    = var.environment
  asg_name       = module.ec2.asg_name
  alb_arn_suffix = module.load_balancer.alb_arn_suffix
  tg_arn_suffix  = module.load_balancer.target_group_arn_suffix
  rds_identifier = module.rds.db_identifier
  sns_email      = var.alert_email

  aws_region = var.aws_region
}
