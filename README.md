# ECIA - Enterprise Cloud Infrastructure Architect

Production-grade AWS infrastructure provisioned entirely with Terraform.

This repository provides a modular, scalable, and secure Infrastructure-as-Code (IaC) implementation for deploying enterprise workloads on AWS. The platform includes networking, compute, storage, databases, identity management, monitoring, and operational tooling, all managed through a single Terraform codebase.

---

# Architecture Overview

```text
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│ VPC                                                     │
│                                                         │
│  Public Subnets                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Application Load Balancer                        │   │
│  │ NAT Gateways                                     │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  Private Application Subnets                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Auto Scaling Group                               │   │
│  │ Amazon EC2 Instances                             │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  Private Database Subnets                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Amazon RDS (MySQL / PostgreSQL)                  │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
         S3         IAM    CloudWatch
```

---

# Architecture Deep Drive

<img src="architect/ecia.png" alt="ECIA Architecture" width="1200">


## Interactive Architecture

👉 [Open Interactive Architecture](https://debasish-87.github.io/ECIA/)

# Repository Structure

```text
ECIA/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── providers.tf
├── versions.tf
│
├── modules/
│   ├── vpc/
│   ├── security-groups/
│   ├── ec2/
│   ├── load-balancer/
│   ├── rds/
│   ├── s3/
│   ├── iam/
│   ├── cloudwatch/
│   ├── waf/
│   ├── kms/
│   ├── route53/
│   └── bastion/
│
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── terraform.tfvars
│   └── prod/
│       └── terraform.tfvars
│
└── Makefile
```

---

# Core Components

## Networking

The networking layer provides:

* Dedicated VPC
* Public, private, and database subnet tiers
* Internet Gateway
* NAT Gateway architecture
* Route tables and subnet associations
* VPC Flow Logs
* Optional VPN Gateway support

### Subnet Design

| Tier     | Purpose                   |
| -------- | ------------------------- |
| Public   | ALB, NAT Gateway, Bastion |
| Private  | Application workloads     |
| Database | RDS instances             |

---

## Security

Security controls include:

* Least-privilege security groups
* IMDSv2 enforcement
* VPC Flow Logs
* SSM Session Manager support
* Secrets Manager integration
* Encrypted EBS volumes
* Encrypted RDS storage
* S3 public access restrictions
* AWS WAF integration

### Security Group Flow

```text
Internet
   │
   ▼
ALB Security Group
   │
   ▼
Application Security Group
   │
   ▼
Database Security Group
```

---

## Compute Platform

The compute layer is built on Amazon EC2 Auto Scaling Groups.

### Features

* Amazon Linux 2023
* Launch Templates
* Auto Scaling Groups
* Instance Refresh
* CloudWatch Agent
* CPU-based Target Tracking Scaling
* Scheduled Scaling Policies
* Encrypted GP3 EBS Volumes

### Scaling Configuration

| Parameter        | Description               |
| ---------------- | ------------------------- |
| Min Capacity     | Minimum instance count    |
| Desired Capacity | Normal operating capacity |
| Max Capacity     | Upper scaling limit       |
| Target CPU       | 60%                       |

---

## Load Balancing

Application traffic is routed through an Application Load Balancer.

### Capabilities

* HTTP listener
* HTTPS listener
* Automatic HTTP to HTTPS redirect
* TLS 1.3 security policy
* Health checks
* Access logging
* Target Group integration

---

## Database Platform

Amazon RDS supports both MySQL and PostgreSQL deployments.

### Features

* Encrypted storage
* Automated backups
* Parameter Groups
* Enhanced Monitoring
* Performance Insights
* CloudWatch log exports
* Multi-AZ deployment support

### Production Configuration

| Setting          | Value    |
| ---------------- | -------- |
| Storage Type     | GP3      |
| Backup Retention | 7 Days   |
| Multi-AZ         | Enabled  |
| Encryption       | Enabled  |
| Monitoring       | Enhanced |

---

## Storage Services

### Application Bucket

Used for:

* Application assets
* Uploads
* Generated content

Features:

* Versioning
* KMS encryption
* Lifecycle management
* Public access blocking

### Logs Bucket

Used for:

* ALB logs
* VPC Flow Logs
* Operational logs

### Terraform State Bucket

Used for:

* Remote Terraform state
* State versioning
* Disaster recovery

---

## Identity and Access Management

### EC2 Instance Role

Provides:

* SSM Session Manager access
* CloudWatch Agent permissions
* S3 access
* Secrets Manager access
* ECR read-only access

### Deployment Role

Supports:

* Infrastructure deployments
* CI/CD integrations
* Terraform automation workflows

---

## Monitoring and Observability

### CloudWatch Dashboard

The dashboard provides visibility into:

* Auto Scaling Groups
* EC2 performance
* Application Load Balancer metrics
* Database performance
* Alarm status

### CloudWatch Alarms

The platform includes alarms for:

#### Application Tier

* High CPU utilization
* Low CPU utilization

#### Load Balancer

* HTTP 5xx errors
* Target 5xx errors
* Unhealthy targets
* High latency

#### Database

* High CPU utilization
* Low storage availability
* High connection count
* Read latency issues

#### Application Logs

* Error rate monitoring

### Alerting

Amazon SNS is used for:

* Email notifications
* Operational alerts
* Incident response workflows

---

# Environment Strategy

## Development

Optimized for cost efficiency.

* Single NAT Gateway
* Single-AZ RDS
* Minimal instance count
* HTTP-only option

## Staging

Production-like environment for testing.

* Single NAT Gateway
* Multiple Availability Zones
* Representative workload sizing

## Production

Designed for high availability and resilience.

* NAT Gateway per Availability Zone
* Multi-AZ RDS deployment
* Increased Auto Scaling capacity
* HTTPS enabled
* Full monitoring and alerting

---

# Deployment

## Initialize Terraform

```bash
terraform init
```

## Validate Configuration

```bash
terraform validate
```

## Format Code

```bash
terraform fmt -recursive
```

## Plan Deployment

```bash
terraform plan \
  -var-file="environments/dev/terraform.tfvars"
```

## Apply Deployment

```bash
terraform apply \
  -var-file="environments/dev/terraform.tfvars"
```

---

# Remote State Configuration

After the initial deployment:

1. Create the Terraform state bucket.
2. Create the DynamoDB lock table.
3. Configure the backend block.
4. Migrate local state.

```bash
terraform init -migrate-state
```

---

# Operational Commands

View outputs:

```bash
terraform output
```

Refresh state:

```bash
terraform refresh
```

List resources:

```bash
terraform state list
```

Start an SSM session:

```bash
aws ssm start-session --target <instance-id>
```

Trigger an Auto Scaling instance refresh:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name <asg-name>
```

---

# Production Readiness Checklist

* Store database credentials in AWS Secrets Manager
* Enable RDS deletion protection
* Restrict SSH access to approved administrative networks
* Configure ACM certificates
* Enable Multi-AZ RDS deployment
* Deploy NAT Gateways in all Availability Zones
* Enable remote Terraform state
* Review IAM permissions
* Confirm SNS subscriptions
* Validate backup and recovery procedures
* Enable WAF protections
* Review CloudWatch alarms and thresholds

---

# Requirements

| Component    | Version |
| ------------ | ------- |
| Terraform    | >= 1.6  |
| AWS Provider | >= 5.0  |
| AWS CLI      | >= 2.x  |

---

# Design Principles

* Infrastructure as Code
* Modular architecture
* High availability
* Security by default
* Least privilege access
* Cost-aware deployment patterns
* Operational visibility
* Production-ready defaults
* Environment isolation
* Reproducible deployments
