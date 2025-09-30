# CyberPot Azure Infrastructure as Code
# Main Terraform configuration for deploying CyberPot on Microsoft Azure

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.5"
    }
  }
}

# Provider configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_termination    = true
      delete_data_disks_on_termination = false
      graceful_shutdown                = false
    }
  }
}

# Local variables
locals {
  name_prefix = "cyberpot-${var.environment}"
  location    = var.azure_location
}

# Resource Group
resource "azurerm_resource_group" "cyberpot" {
  name     = "${local.name_prefix}-rg"
  location = local.location

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "cyberpot" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name
  address_space       = [var.vnet_cidr]

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Subnets
resource "azurerm_subnet" "cyberpot" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.cyberpot.name
  virtual_network_name = azurerm_virtual_network.cyberpot.name
  address_prefixes     = [var.subnet_cidr]
}

# Network Security Group
resource "azurerm_network_security_group" "cyberpot" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "64295"
    source_address_prefixes    = var.allowed_ssh_cidrs
    destination_address_prefix = "*"
  }

  # Web UI access
  security_rule {
    name                       = "WebUI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "64297"
    source_address_prefixes    = var.allowed_web_cidrs
    destination_address_prefix = "*"
  }

  # Honeypot TCP ports
  security_rule {
    name                       = "HoneypotTCP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1-64000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Honeypot UDP ports
  security_rule {
    name                       = "HoneypotUDP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1-64000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound internet access
  security_rule {
    name                       = "Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "cyberpot" {
  subnet_id                 = azurerm_subnet.cyberpot.id
  network_security_group_id = azurerm_network_security_group.cyberpot.id
}

# Public IP for CyberPot instance
resource "azurerm_public_ip" "cyberpot" {
  name                = "${local.name_prefix}-pip"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Azure Key Vault for secrets management
resource "azurerm_key_vault" "cyberpot" {
  count = var.enable_key_vault ? 1 : 0

  name                = "${local.name_prefix}-kv"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku                 = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  access_policy {
    tenant_id = azurerm_user_assigned_identity.cyberpot[0].tenant_id
    object_id = azurerm_user_assigned_identity.cyberpot[0].principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  enable_rbac_authorization       = false

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# User Assigned Identity for CyberPot
resource "azurerm_user_assigned_identity" "cyberpot" {
  count = var.enable_key_vault ? 1 : 0

  name                = "${local.name_prefix}-identity"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Storage Account for CyberPot data
resource "azurerm_storage_account" "cyberpot" {
  name                     = "${local.name_prefix}storage"
  location                 = azurerm_resource_group.cyberpot.location
  resource_group_name      = azurerm_resource_group.cyberpot.name
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Enable advanced threat protection
  advanced_threat_protection {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Storage Container for backups
resource "azurerm_storage_container" "backups" {
  name                  = "cyberpot-backups"
  storage_account_name  = azurerm_storage_account.cyberpot.name
  container_access_type = "private"
}

# Virtual Machine for CyberPot
resource "azurerm_linux_virtual_machine" "cyberpot" {
  name                = "${local.name_prefix}-vm"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name
  size                = var.vm_size
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.cyberpot_ssh.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.cyberpot.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.os_disk_size
    name                 = "${local.name_prefix}-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  # Data disk for CyberPot logs and data
  dynamic "source_image_reference" {
    for_each = var.data_disk_size > 0 ? [1] : []
    content {
      # This block is handled by the data disk resource below
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    environment          = var.environment
    cyberpot_version     = var.cyberpot_version
    web_user_password    = random_password.web_user.result
    ls_web_user_password = random_password.ls_web_user.result
    domain_name          = var.domain_name != "" ? var.domain_name : azurerm_public_ip.cyberpot.ip_address
    admin_username       = var.admin_username
  }))

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.cyberpot.primary_blob_endpoint
  }

  identity {
    type         = var.enable_key_vault ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.enable_key_vault ? [azurerm_user_assigned_identity.cyberpot[0].id] : []
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Data disk for CyberPot
resource "azurerm_managed_disk" "cyberpot_data" {
  count = var.data_disk_size > 0 ? 1 : 0

  name                 = "${local.name_prefix}-data-disk"
  location             = azurerm_resource_group.cyberpot.location
  resource_group_name  = azurerm_resource_group.cyberpot.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size

  encryption_settings {
    enabled = var.enable_encryption
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Attach data disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "cyberpot_data" {
  count = var.data_disk_size > 0 ? 1 : 0

  managed_disk_id    = azurerm_managed_disk.cyberpot_data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.cyberpot.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Network Interface
resource "azurerm_network_interface" "cyberpot" {
  name                = "${local.name_prefix}-nic"
  location            = azurerm_resource_group.cyberpot.location
  resource_group_name = azurerm_resource_group.cyberpot.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cyberpot.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cyberpot.id
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Azure Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "cyberpot" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${local.name_prefix}-action-group"
  resource_group_name = azurerm_resource_group.cyberpot.name
  short_name          = "cyberpot"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email_address
  }

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Azure Monitor Metric Alerts
resource "azurerm_monitor_metric_alert" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${local.name_prefix}-high-cpu"
  resource_group_name = azurerm_resource_group.cyberpot.name
  scopes              = [azurerm_linux_virtual_machine.cyberpot.id]
  description         = "Alert when CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80

    dimension {
      name     = "ResourceId"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.cyberpot[0].id
  }

  frequency   = "PT5M"
  window_size = "PT15M"

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Generate SSH key pair
resource "tls_private_key" "cyberpot_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
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

# Store secrets in Key Vault (if enabled)
resource "azurerm_key_vault_secret" "web_user_password" {
  count = var.enable_key_vault ? 1 : 0

  name         = "web-user-password"
  value        = random_password.web_user.result
  key_vault_id = azurerm_key_vault.cyberpot[0].id

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

resource "azurerm_key_vault_secret" "ls_web_user_password" {
  count = var.enable_key_vault ? 1 : 0

  name         = "ls-web-user-password"
  value        = random_password.ls_web_user.result
  key_vault_id = azurerm_key_vault.cyberpot[0].id

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

resource "azurerm_key_vault_secret" "ssh_private_key" {
  count = var.enable_key_vault ? 1 : 0

  name         = "ssh-private-key"
  value        = tls_private_key.cyberpot_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.cyberpot[0].id

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}
