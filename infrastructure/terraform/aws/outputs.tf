# Outputs for CyberPot AWS deployment

output "cyberpot_instance_id" {
  description = "CyberPot EC2 instance ID"
  value       = aws_instance.cyberpot.id
}

output "cyberpot_public_ip" {
  description = "Public IP address of CyberPot instance"
  value       = aws_instance.cyberpot.public_ip
}

output "cyberpot_private_ip" {
  description = "Private IP address of CyberPot instance"
  value       = aws_instance.cyberpot.private_ip
}

output "cyberpot_eip" {
  description = "Elastic IP address of CyberPot instance"
  value       = aws_eip.cyberpot_eip.public_ip
}

output "cyberpot_url" {
  description = "CyberPot Web UI URL"
  value       = "https://${var.domain_name != "" ? var.domain_name : aws_eip.cyberpot_eip.public_ip}:64297"
}

output "ssh_connection_string" {
  description = "SSH connection string for CyberPot management"
  value       = "ssh -l ${var.cyberpot_ssh_user} -p 64295 ${aws_eip.cyberpot_eip.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.vpc.public_subnets
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.cyberpot_sg.id
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

output "generated_ssh_key" {
  description = "Generated SSH private key for instance access (if created)"
  value       = var.generate_ssh_key ? tls_private_key.cyberpot_ssh_key[0].private_key_pem : null
  sensitive   = true
}

# CloudWatch alarm outputs
output "cloudwatch_alarms" {
  description = "CloudWatch alarm details"
  value = {
    high_cpu_alarm    = aws_cloudwatch_metric_alarm.high_cpu.arn
    high_memory_alarm = aws_cloudwatch_metric_alarm.high_memory.arn
  }
}

# IAM outputs (if created)
output "iam_role_arn" {
  description = "IAM role ARN (if created)"
  value       = var.create_iam_role ? aws_iam_role.cyberpot_role[0].arn : null
}

output "iam_instance_profile" {
  description = "IAM instance profile (if created)"
  value       = var.create_iam_role ? aws_iam_instance_profile.cyberpot_profile[0].name : null
}

# Network outputs
output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.azs
}

# Cost and monitoring outputs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (based on instance type and region)"
  value       = "Calculate using AWS Pricing Calculator"
}

output "monitoring_dashboard_url" {
  description = "CloudWatch monitoring dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=CyberPot-Monitoring"
}
