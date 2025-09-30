# Outputs for CyberPot Azure deployment

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.cyberpot.name
}

output "cyberpot_vm_id" {
  description = "CyberPot VM resource ID"
  value       = azurerm_linux_virtual_machine.cyberpot.id
}

output "cyberpot_public_ip" {
  description = "Public IP address of CyberPot VM"
  value       = azurerm_public_ip.cyberpot.ip_address
}

output "cyberpot_private_ip" {
  description = "Private IP address of CyberPot VM"
  value       = azurerm_network_interface.cyberpot.private_ip_address
}

output "cyberpot_fqdn" {
  description = "Fully qualified domain name of CyberPot VM"
  value       = azurerm_public_ip.cyberpot.fqdn
}

output "cyberpot_url" {
  description = "CyberPot Web UI URL"
  value       = "https://${var.domain_name != "" ? var.domain_name : azurerm_public_ip.cyberpot.ip_address}:64297"
}

output "ssh_connection_string" {
  description = "SSH connection string for CyberPot management"
  value       = "ssh -l ${var.admin_username}@${azurerm_public_ip.cyberpot.ip_address} -p 64295"
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.cyberpot.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.cyberpot.id
}

output "network_security_group_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.cyberpot.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.cyberpot.name
}

output "web_user_password" {
  description = "Generated web user password (store securely!)"
  value       = random_password.web_user.result
  sensitive   = true
}

output "ls_web_user_password" {
  description = "Generated Logstash web user password (store securely!)"
  value       = random_password.ls_web_user.result
  sensitive   = true
}

output "ssh_private_key" {
  description = "Generated SSH private key for VM access"
  value       = tls_private_key.cyberpot_ssh.private_key_pem
  sensitive   = true
}

# Key Vault outputs (if enabled)
output "key_vault_uri" {
  description = "Key Vault URI (if enabled)"
  value       = var.enable_key_vault ? azurerm_key_vault.cyberpot[0].vault_uri : null
}

output "key_vault_id" {
  description = "Key Vault resource ID (if enabled)"
  value       = var.enable_key_vault ? azurerm_key_vault.cyberpot[0].id : null
}

# Monitoring outputs
output "action_group_id" {
  description = "Monitor Action Group ID (if monitoring enabled)"
  value       = var.enable_monitoring ? azurerm_monitor_action_group.cyberpot[0].id : null
}

output "metric_alerts" {
  description = "Metric alert details (if monitoring enabled)"
  value = var.enable_monitoring ? {
    high_cpu = azurerm_monitor_metric_alert.high_cpu[0].id
  } : {}
}

# Cost and monitoring outputs
output "vm_hourly_cost_estimate" {
  description = "Estimated hourly cost for VM (based on region and size)"
  value       = "Calculate using Azure Pricing Calculator"
}

output "monitoring_dashboard_url" {
  description = "Azure Monitor dashboard URL"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_linux_virtual_machine.cyberpot.id}/monitoring"
}

# Network outputs
output "vnet_address_space" {
  description = "Virtual Network address space"
  value       = azurerm_virtual_network.cyberpot.address_space
}

output "subnet_address_prefix" {
  description = "Subnet address prefix"
  value       = azurerm_subnet.cyberpot.address_prefixes
}

# Security outputs
output "network_security_rules" {
  description = "Network Security Group rules"
  value = {
    ssh_rule_id   = azurerm_network_security_group.cyberpot.security_rule.0.id
    webui_rule_id = azurerm_network_security_group.cyberpot.security_rule.1.id
    honeypot_tcp  = azurerm_network_security_group.cyberpot.security_rule.2.id
    honeypot_udp  = azurerm_network_security_group.cyberpot.security_rule.3.id
  }
}

# Backup outputs (if enabled)
output "backup_information" {
  description = "Backup configuration details"
  value = {
    storage_account = azurerm_storage_account.cyberpot.name
    container_name  = azurerm_storage_container.backups.name
    retention_days  = var.backup_retention_days
  }
}

# Identity outputs
output "vm_identity" {
  description = "VM managed identity details"
  value = {
    principal_id = azurerm_linux_virtual_machine.cyberpot.identity[0].principal_id
    tenant_id    = azurerm_linux_virtual_machine.cyberpot.identity[0].tenant_id
  }
}

# Deployment outputs
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment        = var.environment
    location           = var.azure_location
    vm_size            = var.vm_size
    cyberpot_version   = var.cyberpot_version
    data_disk_size     = var.data_disk_size
    monitoring_enabled = var.enable_monitoring
    key_vault_enabled  = var.enable_key_vault
  }
}
