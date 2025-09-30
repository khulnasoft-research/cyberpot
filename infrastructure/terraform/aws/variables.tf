# Variables for CyberPot AWS deployment

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for CyberPot"
  type        = string
  default     = "t3.large"

  validation {
    condition     = contains(["t3.medium", "t3.large", "t3.xlarge", "c5.large", "c5.xlarge", "m5.large", "m5.xlarge"], var.instance_type)
    error_message = "Instance type must be one of: t3.medium, t3.large, t3.xlarge, c5.large, c5.xlarge, m5.large, m5.xlarge."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Size of data volume in GB (for CyberPot logs and data)"
  type        = number
  default     = 256
}

variable "cyberpot_ami_id" {
  description = "Custom AMI ID for CyberPot (leave empty to use default Ubuntu)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name of SSH key pair for instance access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to CyberPot"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_web_cidrs" {
  description = "List of CIDR blocks allowed to access CyberPot Web UI"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain name for CyberPot (optional, will use IP if not provided)"
  type        = string
  default     = ""
}

variable "cyberpot_version" {
  description = "CyberPot version to deploy"
  type        = string
  default     = "24.04.1"
}

variable "create_iam_role" {
  description = "Create IAM role for enhanced monitoring and security"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (60, 300, 900, 3600, etc.)"
  type        = number
  default     = 300
}

# Network configuration variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones >= 1 && var.availability_zones <= 3
    error_message = "Number of availability zones must be between 1 and 3."
  }
}

# Security and compliance variables
variable "enable_encryption" {
  description = "Enable encryption for all volumes"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (uses default AWS managed key if not specified)"
  type        = string
  default     = ""
}

# Auto scaling variables (for production deployments)
variable "enable_auto_scaling" {
  description = "Enable auto scaling for high availability"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 3
}

variable "desired_instances" {
  description = "Desired number of instances in auto scaling group"
  type        = number
  default     = 1
}

# Cost optimization variables
variable "enable_spot_instances" {
  description = "Use spot instances for cost optimization (not recommended for production honeypots)"
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "Maximum spot price (only used if enable_spot_instances is true)"
  type        = string
  default     = ""
}

# Logging and monitoring variables
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (5-minute intervals)"
  type        = bool
  default     = true
}

# Backup configuration
variable "enable_automated_backups" {
  description = "Enable automated EBS snapshots"
  type        = bool
  default     = true
}

variable "backup_window" {
  description = "Preferred backup window (cron format)"
  type        = string
  default     = "03:00-04:00"
}

# Network security variables
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network traffic monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention in days"
  type        = number
  default     = 30
}
