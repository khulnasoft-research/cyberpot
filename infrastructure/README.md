# 🚀 CyberPot Infrastructure as Code (IaC) Documentation

## Overview

This comprehensive Infrastructure as Code (IaC) setup provides automated deployment and management of CyberPot honeypot platforms across multiple cloud providers (AWS, Azure, GCP) with production-ready configurations.

## 🎯 Features

- **Multi-Cloud Support**: Deploy to AWS, Azure, or GCP
- **Environment Management**: Dev, staging, and production configurations
- **Automated Provisioning**: Ansible playbooks for complete server setup
- **Security Hardening**: Built-in security best practices
- **Monitoring Integration**: Cloud-native monitoring and alerting
- **Backup & Recovery**: Automated backup strategies
- **Scalability**: Support for distributed deployments
- **Compliance Ready**: GDPR and security compliance features

## 📁 Project Structure

```
infrastructure/
├── terraform/                 # Terraform configurations
│   ├── aws/                  # AWS deployment
│   │   ├── main.tf          # Main Terraform config
│   │   ├── variables.tf     # Input variables
│   │   ├── outputs.tf       # Output values
│   │   └── templates/       # User data templates
│   ├── azure/               # Azure deployment
│   └── gcp/                 # GCP deployment
├── ansible/                 # Ansible automation
│   ├── playbooks/           # Main playbooks
│   │   └── cyberpot_provisioning.yml
│   └── roles/               # Ansible roles
│       ├── system_hardening/
│       ├── docker_installation/
│       ├── cyberpot_installation/
│       ├── cyberpot_configuration/
│       ├── monitoring_setup/
│       └── security_configuration/
├── templates/               # Configuration templates
│   ├── deployment_config.py # Environment configs
│   └── README.md           # This file
└── deploy-cyberpot.py      # Main deployment script
```

## 🚀 Quick Start

### Prerequisites

1. **Required Tools**:
   - Terraform >= 1.0
   - Ansible >= 2.10
   - Python 3.8+
   - Git
   - Cloud provider CLI tools (aws, az, gcloud)

2. **Cloud Accounts**:
   - AWS account with appropriate permissions
   - Azure subscription with contributor access
   - GCP project with compute admin permissions

### Installation

```bash
# Clone the repository
git clone https://github.com/khulnasoft/cyberpot.git
cd cyberpot/infrastructure

# Install Python dependencies
pip install -r requirements.txt

# Verify all tools are installed
python3 deploy-cyberpot.py --verify-only
```

## 🌐 Deployment Options

### 1. AWS Deployment

```bash
# Deploy to AWS development environment
python3 deploy-cyberpot.py \
    --provider aws \
    --environment dev \
    --region us-east-1

# Deploy to AWS production
python3 deploy-cyberpot.py \
    --provider aws \
    --environment prod \
    --region us-west-2
```

### 2. Azure Deployment

```bash
# Deploy to Azure development
python3 deploy-cyberpot.py \
    --provider azure \
    --environment dev \
    --region "East US"

# Deploy to Azure production
python3 deploy-cyberpot.py \
    --provider azure \
    --environment prod \
    --region "West Europe"
```

### 3. GCP Deployment

```bash
# Deploy to GCP development
python3 deploy-cyberpot.py \
    --provider gcp \
    --environment dev \
    --region us-central1 \
    --project-id your-project-id

# Deploy to GCP production
python3 deploy-cyberpot.py \
    --provider gcp \
    --environment prod \
    --region europe-west1 \
    --project-id your-project-id
```

## ⚙️ Configuration

### Environment Configurations

The deployment system supports multiple environment configurations:

#### Development (dev)
- **Instance Type**: t3.medium (AWS), Standard_B2s (Azure), e2-medium (GCP)
- **Storage**: 128GB data volume
- **Monitoring**: Basic monitoring enabled
- **Honeypots**: Limited set for testing

#### Production (prod)
- **Instance Type**: t3.large (AWS), Standard_B4ms (Azure), n2-standard-2 (GCP)
- **Storage**: 256GB data volume
- **Monitoring**: Comprehensive monitoring and alerting
- **Honeypots**: All available honeypots enabled

#### High Security
- **Instance Type**: c5.xlarge (AWS), Standard_F8s_v2 (Azure), n2-highmem-4 (GCP)
- **Security**: Enhanced security features
- **Compliance**: GDPR compliance features

### Custom Configuration

Edit `templates/deployment_config.py` to customize:

```python
cyberpot_custom_config = {
    'environment': 'custom',
    'instance_type': {
        'aws': 'c5.2xlarge',
        'azure': 'Standard_F16s_v2',
        'gcp': 'n2-highmem-8'
    },
    'data_volume_size': 512,
    'monitoring': {
        'enabled': True,
        'detailed': True,
        'alerts': ['cpu', 'memory', 'disk', 'network']
    }
}
```

## 🔧 Advanced Usage

### Ansible Provisioning

For manual server provisioning using Ansible:

```bash
# Create inventory file
cat > inventory.ini << EOF
[cyberpot_servers]
your-server-ip ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

[cyberpot_servers:vars]
cyberpot_version=24.04.1
environment=prod
EOF

# Run Ansible playbook
ansible-playbook -i inventory.ini playbooks/cyberpot_provisioning.yml
```

### Terraform Only Deployment

For infrastructure-only deployment without Ansible:

```bash
cd terraform/aws
terraform init
terraform plan -var="environment=prod" -var="instance_type=t3.large"
terraform apply
```

### Custom Honeypot Configuration

Enable/disable specific honeypots:

```bash
# Edit docker-compose.yml after deployment
vim /home/cyberpot/cyberpot/docker-compose.yml

# Restart CyberPot
sudo systemctl restart cyberpot
```

## 🔒 Security Features

### Automated Security Hardening

The deployment includes comprehensive security measures:

- **SSH Security**: Key-only authentication, custom SSH port (64295)
- **Firewall**: UFW with strict rules, only necessary ports open
- **System Updates**: Automatic security updates
- **Audit Logging**: Comprehensive audit trails
- **Intrusion Detection**: Fail2Ban protection
- **Rootkit Detection**: rkhunter integration

### Cloud Security

- **AWS**: Security groups, IAM roles, CloudTrail integration
- **Azure**: Network Security Groups, Azure AD integration, Azure Security Center
- **GCP**: Firewall rules, IAM service accounts, Cloud Armor integration

## 📊 Monitoring & Alerting

### Integrated Monitoring

- **System Metrics**: CPU, memory, disk, network monitoring
- **CyberPot Metrics**: Honeypot activity, attack patterns
- **Security Events**: Failed logins, suspicious activities
- **Docker Monitoring**: Container health and resource usage

### Alert Configuration

Alerts are automatically configured for:

- High CPU usage (>80%)
- High memory usage (>85%)
- Disk space low (<20% free)
- Service failures
- Security events

### Notification Channels

- Email notifications
- Slack integration (configurable)
- SMS alerts for critical issues
- PagerDuty integration for production

## 💾 Backup & Recovery

### Automated Backups

- **Daily Backups**: Configuration and honeypot data
- **Retention**: 7-30 days based on environment
- **Cloud Storage**: AWS S3, Azure Blob, GCP Cloud Storage
- **Encryption**: All backups encrypted

### Recovery Procedures

```bash
# Stop CyberPot services
sudo systemctl stop cyberpot

# Restore from backup
cd /home/cyberpot
sudo tar -xzf cyberpot_backup_*.tar.gz

# Restore configuration
sudo cp backup/.env .env

# Start services
sudo systemctl start cyberpot
```

## 🔄 Scaling & High Availability

### Auto Scaling

Production deployments support auto scaling:

- **Min Instances**: 2 (for high availability)
- **Max Instances**: 5 (based on load)
- **Scale Triggers**: CPU > 70%, Memory > 80%

### Distributed Deployment

For large-scale deployments:

1. **Deploy Hive**: Central management and data aggregation
2. **Deploy Sensors**: Distributed honeypot instances
3. **Configure Networking**: Secure communication between components

```bash
# Deploy Hive
python3 deploy-cyberpot.py --provider aws --environment prod --region us-east-1

# Deploy Sensor
CYBERPOT_TYPE=SENSOR python3 deploy-cyberpot.py --provider aws --environment prod --region eu-west-1
```

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Failures

```bash
# Check Terraform logs
cd terraform/aws
terraform show

# Check Ansible logs
ansible-playbook -i inventory.ini playbooks/cyberpot_provisioning.yml -v

# View system logs
sudo journalctl -u cyberpot -n 100
```

#### Network Issues

```bash
# Test connectivity
ping your-cyberpot-ip

# Check firewall
sudo ufw status

# Test ports
telnet your-cyberpot-ip 64297
```

#### Performance Issues

```bash
# Check system resources
htop

# Monitor Docker
docker stats

# Check logs
sudo tail -f /home/cyberpot/cyberpot/data/cyberpotinit.log
```

### Getting Help

1. **Check Documentation**: Review this README and deployment docs
2. **View Logs**: Check system and CyberPot logs
3. **Test Connectivity**: Verify network and firewall configuration
4. **Community Support**: Use GitHub Issues and Discussions

## 📚 Additional Resources

- **CyberPot Documentation**: https://github.com/khulnasoft/cyberpot
- **Terraform Documentation**: https://www.terraform.io/docs
- **Ansible Documentation**: https://docs.ansible.com
- **Cloud Provider Docs**: AWS/Azure/GCP documentation

## 🔄 Updates and Maintenance

### Updating CyberPot

```bash
# Update CyberPot code
cd /home/cyberpot/cyberpot
git pull origin main

# Update IaC tools
python3 deploy-cyberpot.py --environment prod --update-only
```

### Maintenance Tasks

- **Daily**: Automated cleanup and monitoring
- **Weekly**: Security updates and backup verification
- **Monthly**: Full system review and performance analysis

## 📋 Environment Variables

### Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Deployment environment | `dev` |
| `instance_type` | VM instance type | Provider-specific |
| `data_volume_size` | Data disk size (GB) | 128-512 |
| `monitoring` | Enable monitoring | `true` |
| `backup_retention_days` | Backup retention | 7-30 |

### Ansible Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cyberpot_user` | System user for CyberPot | `cyberpot` |
| `cyberpot_version` | CyberPot version | `24.04.1` |
| `ssh_port` | SSH port | `64295` |
| `web_port` | Web UI port | `64297` |

## 🏷️ Cost Optimization

### Development Environment
- **Estimated Cost**: $25-50/month
- **Optimization Tips**: Use smallest instance types, disable monitoring

### Production Environment
- **Estimated Cost**: $100-300/month
- **Optimization Tips**: Use reserved instances, auto scaling, spot instances

### Cost Monitoring

- **AWS**: Cost Explorer, Budgets, Cost and Usage Reports
- **Azure**: Cost Management, Budgets, Cost Analysis
- **GCP**: Cost Management, Budgets, Cost Reports

## 🔐 Compliance & Security

### GDPR Compliance
- Data encryption at rest and in transit
- Data retention policies
- Audit logging for compliance
- Data processing agreements

### Security Standards
- CIS benchmarks compliance
- SOC 2 Type II compliance features
- ISO 27001 alignment
- NIST framework support

---

## 🤝 Contributing

To contribute to the IaC setup:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in development environment
5. Submit a pull request

## 📄 License

This Infrastructure as Code setup follows the same license as the main CyberPot project.

---

**Happy Honeypot Hunting!** 🐝🔒

*Generated by CyberPot Infrastructure as Code Automation*
