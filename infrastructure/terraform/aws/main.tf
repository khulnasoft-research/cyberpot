# CyberPot AWS Infrastructure as Code
# Main Terraform configuration for deploying CyberPot on AWS

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CyberPot"
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  name_prefix = "cyberpot-${var.environment}"
  vpc_cidr    = "10.0.0.0/16"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = local.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for i, az in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(local.vpc_cidr, 8, i + 1)]
  public_subnets  = [for i, az in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(local.vpc_cidr, 8, i + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "production"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Security group configurations
  manage_default_security_group = true
  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# Security Groups
resource "aws_security_group" "cyberpot_sg" {
  name_prefix = "${local.name_prefix}-cyberpot"
  description = "Security group for CyberPot honeypot services"
  vpc_id      = module.vpc.vpc_id

  # SSH access
  ingress {
    from_port   = 64295
    to_port     = 64295
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access for CyberPot management"
  }

  # Web UI access
  ingress {
    from_port   = 64297
    to_port     = 64297
    protocol    = "tcp"
    cidr_blocks = var.allowed_web_cidrs
    description = "CyberPot Web UI access"
  }

  # Honeypot ports (comprehensive range)
  ingress {
    from_port   = 1
    to_port     = 64000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Honeypot TCP services"
  }

  ingress {
    from_port   = 1
    to_port     = 64000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Honeypot UDP services"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-cyberpot"
  }
}

# EC2 Instance for CyberPot
resource "aws_instance" "cyberpot" {
  ami                    = var.cyberpot_ami_id != "" ? var.cyberpot_ami_id : data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.cyberpot_sg.id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  key_name               = var.key_pair_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${local.name_prefix}-root"
    }
  }

  # Additional EBS volumes for CyberPot data
  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_type           = "gp3"
    volume_size           = var.data_volume_size
    delete_on_termination = false
    encrypted             = true

    tags = {
      Name = "${local.name_prefix}-data"
    }
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    environment          = var.environment
    cyberpot_version     = var.cyberpot_version
    web_user_password    = random_password.web_user.result
    ls_web_user_password = random_password.ls_web_user.result
    domain_name          = var.domain_name != "" ? var.domain_name : aws_instance.cyberpot.public_ip
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = true

  tags = {
    Name = "${local.name_prefix}-instance"
  }
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name  = "name"
    value = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  }

  filter {
    name  = "virtualization-type"
    value = "hvm"
  }
}

# Generate random passwords
resource "random_password" "web_user" {
  length  = 16
  special = true
}

resource "random_password" "ls_web_user" {
  length  = 16
  special = true
}

# Elastic IP for consistent IP address
resource "aws_eip" "cyberpot_eip" {
  instance = aws_instance.cyberpot.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    InstanceId = aws_instance.cyberpot.id
  }

  tags = {
    Name = "${local.name_prefix}-high-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${local.name_prefix}-high-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "20" # Less than 20% free memory
  alarm_description   = "This metric monitors EC2 memory utilization"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    InstanceId = aws_instance.cyberpot.id
  }

  tags = {
    Name = "${local.name_prefix}-high-memory"
  }
}

# IAM Role for CyberPot instance (optional - for enhanced security)
resource "aws_iam_role" "cyberpot_role" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = {
    Name = "${local.name_prefix}-role"
  }
}

resource "aws_iam_instance_profile" "cyberpot_profile" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-profile"
  role = aws_iam_role.cyberpot_role[0].name

  tags = {
    Name = "${local.name_prefix}-profile"
  }
}
