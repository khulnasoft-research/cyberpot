# Variables for CyberPot GCP deployment

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for deployment"
  type        = string
  default     = "us-central1"

  validation {
    condition = contains([
      "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4",
      "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6",
      "asia-east1", "asia-east2", "asia-northeast1", "asia-northeast2", "asia-northeast3",
      "asia-south1", "asia-southeast1", "asia-southeast2"
    ], var.gcp_region)
    error_message = "Please specify a valid GCP region."
  }
}

variable "gcp_zone" {
  description = "GCP zone for deployment"
  type        = string
  default     = "us-central1-a"
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

variable "machine_type" {
  description = "GCP machine type for CyberPot"
  type        = string
  default     = "e2-medium"

  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium",
      "n2-standard-2", "n2-standard-4", "n2-standard-8",
      "n2-highmem-2", "n2-highmem-4", "n2-highmem-8"
    ], var.machine_type)
    error_message = "Machine type must be one of the supported types for CyberPot."
  }
}

variable "boot_disk_size" {
  description = "Size of boot disk in GB"
  type        = number
  default     = 50
}

variable "data_disk_size" {
  description = "Size of data disk in GB (0 to disable)"
  type        = number
  default     = 256
}

variable "cyberpot_image" {
  description = "Custom image name for CyberPot (leave empty to use Ubuntu 22.04)"
  type        = string
  default     = ""
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
  description = "Domain name for CyberPot (optional, will use external IP if not provided)"
  type        = string
  default     = ""
}

variable "cyberpot_version" {
  description = "CyberPot version to deploy"
  type        = string
  default     = "24.04.1"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_ip" {
  description = "Private IP address for the instance (optional)"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable Cloud Monitoring and alerting"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "kms_key_link" {
  description = "KMS key self-link for disk encryption (optional)"
  type        = string
  default     = ""
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_aggregation_interval" {
  description = "VPC Flow Logs aggregation interval"
  type        = string
  default     = "INTERVAL_5_MIN"

  validation {
    condition     = contains(["INTERVAL_5_MIN", "INTERVAL_1_MIN", "INTERVAL_15_MIN"], var.flow_logs_aggregation_interval)
    error_message = "Flow logs aggregation interval must be one of: INTERVAL_5_MIN, INTERVAL_1_MIN, INTERVAL_15_MIN."
  }
}

variable "flow_logs_metadata" {
  description = "VPC Flow Logs metadata inclusion"
  type        = string
  default     = "INCLUDE_ALL_METADATA"
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "maintenance_window" {
  description = "Maintenance window settings"
  type = object({
    day         = string
    hour        = number
    update_type = string
  })
  default = {
    day         = "SUNDAY"
    hour        = 2
    update_type = "CANARY"
  }
}

variable "enable_os_patch_management" {
  description = "Enable OS patch management"
  type        = bool
  default     = true
}

variable "os_patch_day_of_week" {
  description = "Day of week for OS patches"
  type        = string
  default     = "SUNDAY"
}

variable "os_patch_window_start_time" {
  description = "Start time for OS patch window"
  type        = string
  default     = "02:00"
}

variable "labels" {
  description = "Additional labels for resources"
  type        = map(string)
  default     = {}
}

# Cost optimization variables
variable "enable_sustained_use_discounts" {
  description = "Enable sustained use discounts for committed use"
  type        = bool
  default     = false
}

variable "enable_preemptible_instances" {
  description = "Use preemptible instances for cost optimization (not recommended for production honeypots)"
  type        = bool
  default     = false
}

variable "preemptible_maintenance_interval" {
  description = "Maintenance interval for preemptible instances"
  type        = string
  default     = "PERIODIC"
}

# Security variables
variable "enable_secure_boot" {
  description = "Enable secure boot for the instance"
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Enable virtual TPM for the instance"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for the instance"
  type        = bool
  default     = true
}

# Network variables
variable "enable_private_google_access" {
  description = "Enable private Google access for the subnet"
  type        = bool
  default     = true
}

variable "network_tier" {
  description = "Network tier for external IP"
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "Network tier must be either PREMIUM or STANDARD."
  }
}

# Logging variables
variable "log_retention_days" {
  description = "Cloud Logging retention period in days"
  type        = number
  default     = 30
}

# Auto scaling variables (for future use)
variable "enable_autoscaling" {
  description = "Enable managed instance group for high availability"
  type        = bool
  default     = false
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 3
}

variable "cpu_utilization_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 0.6
}
