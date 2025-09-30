# Variables for CyberPot Azure deployment

variable "azure_location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Europe", "North Europe", "UK South", "UK West",
      "Canada Central", "Canada East",
      "Australia East", "Australia Southeast",
      "Japan East", "Japan West",
      "Korea Central", "Korea South"
    ], var.azure_location)
    error_message = "Please specify a valid Azure region."
  }
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

variable "vm_size" {
  description = "Azure VM size for CyberPot"
  type        = string
  default     = "Standard_B2s"

  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v4",
      "Standard_F4s_v2", "Standard_F8s_v2"
    ], var.vm_size)
    error_message = "VM size must be one of the supported sizes for CyberPot."
  }
}

variable "os_disk_size" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 50
}

variable "data_disk_size" {
  description = "Size of data disk in GB (0 to disable)"
  type        = number
  default     = 256
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "cyberpotadmin"

  validation {
    condition     = length(var.admin_username) >= 2 && length(var.admin_username) <= 16
    error_message = "Admin username must be between 2 and 16 characters."
  }
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

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_key_vault" {
  description = "Enable Azure Key Vault for secrets management"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption for managed disks"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor alerts"
  type        = bool
  default     = true
}

variable "alert_email_address" {
  description = "Email address for alerts (required if monitoring enabled)"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (optional)"
  type        = string
  default     = ""
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_account_replication)
    error_message = "Storage replication must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

variable "vm_backup_policy" {
  description = "VM backup policy settings"
  type = object({
    enabled           = bool
    frequency         = string
    time              = string
    retention_daily   = number
    retention_weekly  = number
    retention_monthly = number
  })
  default = {
    enabled           = true
    frequency         = "Daily"
    time              = "02:00"
    retention_daily   = 7
    retention_weekly  = 4
    retention_monthly = 12
  }
}

variable "network_watcher" {
  description = "Enable Azure Network Watcher"
  type        = bool
  default     = true
}

variable "diagnostic_settings" {
  description = "Diagnostic settings for resources"
  type = object({
    enabled            = bool
    retention_days     = number
    storage_account_id = string
  })
  default = {
    enabled            = true
    retention_days     = 30
    storage_account_id = ""
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Security and compliance variables
variable "enable_advanced_threat_protection" {
  description = "Enable Azure Advanced Threat Protection"
  type        = bool
  default     = true
}

variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "security_center_pricing_tier" {
  description = "Security Center pricing tier"
  type        = string
  default     = "Standard"
}

# Cost optimization variables
variable "enable_auto_shutdown" {
  description = "Enable automatic VM shutdown for cost optimization"
  type        = bool
  default     = false
}

variable "auto_shutdown_time" {
  description = "Time for automatic shutdown (24-hour format)"
  type        = string
  default     = "19:00"
}

variable "shutdown_time_zone" {
  description = "Time zone for auto shutdown"
  type        = string
  default     = "UTC"
}

# High availability variables
variable "enable_availability_set" {
  description = "Enable availability set for high availability"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(number)
  default     = [1]
}

# Network security variables
variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "DDoS Protection Plan resource ID (required if DDoS protection enabled)"
  type        = string
  default     = ""
}
