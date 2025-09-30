# Outputs for CyberPot GCP deployment

output "instance_name" {
  description = "CyberPot instance name"
  value       = google_compute_instance.cyberpot.name
}

output "instance_id" {
  description = "CyberPot instance ID"
  value       = google_compute_instance.cyberpot.instance_id
}

output "external_ip" {
  description = "External IP address of CyberPot instance"
  value       = google_compute_address.cyberpot.address
}

output "internal_ip" {
  description = "Internal IP address of CyberPot instance"
  value       = google_compute_instance.cyberpot.network_interface[0].network_ip
}

output "cyberpot_url" {
  description = "CyberPot Web UI URL"
  value       = "https://${var.domain_name != "" ? var.domain_name : google_compute_address.cyberpot.address}:64297"
}

output "ssh_connection_string" {
  description = "SSH connection string for CyberPot management"
  value       = "gcloud compute ssh --zone=${var.gcp_zone} ${google_compute_instance.cyberpot.name} --tunnel-through-iap"
}

output "vpc_network" {
  description = "VPC network name"
  value       = google_compute_network.cyberpot.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.cyberpot.name
}

output "storage_bucket" {
  description = "Storage bucket for backups"
  value       = google_storage_bucket.cyberpot_backups.name
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.cyberpot.email
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

# Firewall outputs
output "firewall_rules" {
  description = "Firewall rules created"
  value = {
    ssh_rule     = google_compute_firewall.ssh.name
    webui_rule   = google_compute_firewall.webui.name
    honeypot_tcp = google_compute_firewall.honeypot_tcp.name
    honeypot_udp = google_compute_firewall.honeypot_udp.name
  }
}

# Monitoring outputs
output "monitoring_alerts" {
  description = "Cloud Monitoring alert policies"
  value = var.enable_monitoring ? {
    high_cpu    = google_monitoring_alert_policy.high_cpu[0].name
    high_memory = google_monitoring_alert_policy.high_memory[0].name
  } : {}
}

# Cost and monitoring outputs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (based on machine type and region)"
  value       = "Calculate using GCP Pricing Calculator"
}

output "monitoring_dashboard_url" {
  description = "Cloud Monitoring dashboard URL"
  value       = "https://console.cloud.google.com/monitoring/dashboards?project=${var.gcp_project_id}"
}

# Network outputs
output "vpc_network_self_link" {
  description = "VPC network self-link"
  value       = google_compute_network.cyberpot.self_link
}

output "subnet_self_link" {
  description = "Subnet self-link"
  value       = google_compute_subnetwork.cyberpot.self_link
}

# Security outputs
output "service_account_id" {
  description = "Service account unique ID"
  value       = google_service_account.cyberpot.unique_id
}

output "kms_key_link" {
  description = "KMS key used for disk encryption"
  value       = var.kms_key_link != "" ? var.kms_key_link : "Google managed encryption"
}

# Backup outputs
output "backup_configuration" {
  description = "Backup configuration details"
  value = {
    bucket_name    = google_storage_bucket.cyberpot_backups.name
    retention_days = var.backup_retention_days
    schedule       = var.backup_schedule
  }
}

# Deployment summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment        = var.environment
    region             = var.gcp_region
    zone               = var.gcp_zone
    machine_type       = var.machine_type
    cyberpot_version   = var.cyberpot_version
    monitoring_enabled = var.enable_monitoring
    data_disk_size     = var.data_disk_size
  }
}
