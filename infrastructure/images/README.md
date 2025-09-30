# CyberPot OS Image Management System
# Automated creation and management of custom OS images for CyberPot deployment

This directory contains the complete OS image management system for CyberPot:

## 📁 Directory Structure

```
infrastructure/images/
├── packer/                          # Packer templates for image creation
│   ├── aws/                        # AWS AMI creation
│   │   ├── cyberpot-base.json      # Base CyberPot AMI
│   │   ├── cyberpot-enterprise.json # Enterprise AMI
│   │   └── variables.json          # AWS variables
│   ├── azure/                      # Azure managed image creation
│   │   ├── cyberpot-base.json      # Base CyberPot image
│   │   ├── cyberpot-enterprise.json # Enterprise image
│   │   └── variables.json          # Azure variables
│   ├── gcp/                        # GCP image creation
│   │   ├── cyberpot-base.json      # Base CyberPot image
│   │   ├── cyberpot-enterprise.json # Enterprise image
│   │   └── variables.json          # GCP variables
│   └── shared/                     # Shared Packer resources
│       ├── scripts/                # Common provisioning scripts
│       └── templates/              # Shared templates
├── templates/                      # Image configuration templates
│   ├── base-image.json             # Base image configuration
│   ├── enterprise-image.json       # Enterprise image configuration
│   └── security-image.json         # Security-hardened image
├── scripts/                        # Image creation and management scripts
│   ├── create-images.sh            # Main image creation script
│   ├── update-images.sh            # Image update script
│   ├── validate-images.sh          # Image validation script
│   └── cleanup-images.sh           # Image cleanup script
└── README.md                       # This documentation

enterprise/images/                   # Runtime image management
├── aws/                           # AWS AMI management
├── azure/                         # Azure image management
└── gcp/                           # GCP image management
```

## 🚀 Quick Start

### Create Base Images for All Providers
```bash
# Create base CyberPot images for all cloud providers
./infrastructure/images/scripts/create-images.sh --type base --providers all

# Create enterprise images with advanced features
./infrastructure/images/scripts/create-images.sh --type enterprise --providers aws,azure
```

### Update Existing Images
```bash
# Update all images to latest CyberPot version
./infrastructure/images/scripts/update-images.sh --version 24.04.2

# Update specific provider images
./infrastructure/images/scripts/update-images.sh --provider aws --version 24.04.2
```

## 📋 Image Types

### 🏗️ Base Images (`cyberpot-base`)
- **Purpose**: Minimal CyberPot installation for development and testing
- **Size**: ~2-3 GB
- **Features**:
  - Ubuntu 22.04 LTS base
  - Docker and Docker Compose
  - Basic CyberPot installation
  - SSH access configured
  - Basic monitoring setup

### 🏢 Enterprise Images (`cyberpot-enterprise`)
- **Purpose**: Full-featured CyberPot for production deployments
- **Size**: ~4-6 GB
- **Features**:
  - All base image features
  - Advanced security hardening
  - Comprehensive monitoring stack
  - Threat intelligence tools
  - Vulnerability scanning
  - Digital forensics tools
  - SIEM integration capabilities

### 🔒 Security Images (`cyberpot-security`)
- **Purpose**: Maximum security CyberPot for high-security environments
- **Size**: ~3-5 GB
- **Features**:
  - Enhanced security hardening
  - Advanced firewall configuration
  - Intrusion detection systems
  - Encrypted storage by default
  - Compliance frameworks (SOC2, GDPR, NIST)

## ☁️ Cloud Provider Support

### AWS (Amazon Machine Images - AMIs)
```bash
# Create AWS AMI
./infrastructure/images/scripts/create-images.sh --provider aws --type base

# Share AMI across accounts
./infrastructure/images/scripts/share-ami.sh --ami-id ami-12345 --account-id 123456789
```

### Azure (Managed Images)
```bash
# Create Azure managed image
./infrastructure/images/scripts/create-images.sh --provider azure --type enterprise

# Copy image to different regions
./infrastructure/images/scripts/copy-azure-image.sh --image-name cyberpot-base --source-region eastus --dest-region westus2
```

### GCP (Compute Images)
```bash
# Create GCP compute image
./infrastructure/images/scripts/create-images.sh --provider gcp --type base

# Share image across projects
./infrastructure/images/scripts/share-gcp-image.sh --image-name cyberpot-enterprise --project-id target-project
```

## 🔧 Image Customization

### Environment Variables
Images can be customized using environment variables:

```json
{
  "cyberpot_version": "24.04.1",
  "environment": "production",
  "monitoring_enabled": true,
  "security_level": "high",
  "threat_intelligence": true,
  "log_retention_days": 90
}
```

### Custom Scripts
Add custom provisioning scripts in the appropriate provider directory:

```
packer/aws/scripts/
├── 01-install-dependencies.sh
├── 02-configure-cyberpot.sh
├── 03-setup-monitoring.sh
└── 04-security-hardening.sh
```

## 📊 Image Management

### List Available Images
```bash
# List all CyberPot images across providers
./infrastructure/images/scripts/list-images.sh

# List AWS AMIs only
./infrastructure/images/scripts/list-images.sh --provider aws

# List images by type
./infrastructure/images/scripts/list-images.sh --type enterprise
```

### Image Validation
```bash
# Validate image functionality
./infrastructure/images/scripts/validate-images.sh --image-id ami-12345

# Test enterprise features
./infrastructure/images/scripts/validate-images.sh --type enterprise --provider aws
```

### Image Cleanup
```bash
# Clean old images (keep last 5 versions)
./infrastructure/images/scripts/cleanup-images.sh --keep-versions 5

# Remove specific image
./infrastructure/images/scripts/cleanup-images.sh --image-id ami-old123 --force
```

## 🔄 Image Update Process

### Automated Updates
```bash
# Update all images weekly
0 2 * * 0 /path/to/cyberpot/infrastructure/images/scripts/update-images.sh --auto

# Update on CyberPot version release
./infrastructure/images/scripts/update-images.sh --version $(curl -s https://api.github.com/repos/khulnasoft/cyberpot/releases/latest | jq -r '.tag_name')
```

### Manual Updates
```bash
# Update to specific CyberPot version
./infrastructure/images/scripts/update-images.sh --version 24.04.2 --providers aws,azure

# Update with custom configuration
./infrastructure/images/scripts/update-images.sh --version 24.04.2 --config custom-config.json
```

## 🏭 Packer Configuration

### Base Image Template (AWS Example)
```json
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-1",
    "source_ami": "ami-0abcdef1234567890",
    "instance_type": "t3.medium",
    "ssh_username": "ubuntu",
    "ami_name": "cyberpot-base-{{timestamp}}",
    "tags": {
      "Name": "CyberPot Base Image",
      "Version": "{{user `cyberpot_version`}}",
      "Environment": "{{user `environment`}}"
    }
  }],
  "provisioners": [
    {
      "type": "shell",
      "scripts": [
        "scripts/01-install-base.sh",
        "scripts/02-install-cyberpot.sh",
        "scripts/03-configure-services.sh"
      ]
    }
  ]
}
```

## 📈 Cost Optimization

### Image Storage Costs
- **AWS**: $0.05 per GB-month for snapshots
- **Azure**: $0.05 per GB-month for managed disks
- **GCP**: $0.04 per GB-month for images

### Optimization Strategies
- **Deduplication**: Use common base images
- **Compression**: Enable EBS snapshot compression
- **Lifecycle**: Automatic cleanup of old images
- **Sharing**: Share images across accounts/regions

## 🔒 Security Considerations

### Image Security
- **Base image validation**: Verify source image integrity
- **Secure provisioning**: Use encrypted connections for Packer
- **Access control**: Restrict image sharing to authorized accounts
- **Vulnerability scanning**: Scan images before deployment

### Compliance
- **Audit trails**: Track all image creation and modifications
- **Approval workflows**: Require approval for production images
- **Compliance scanning**: Automated compliance checks
- **Retention policies**: Maintain image history for forensics

## 🚨 Troubleshooting

### Common Issues

**Packer Build Failures:**
```bash
# Check Packer logs
tail -f packer.log

# Validate template
packer validate template.json

# Test with debug
packer build -debug template.json
```

**Image Deployment Issues:**
```bash
# Verify image exists
./infrastructure/images/scripts/list-images.sh

# Check image permissions
./infrastructure/images/scripts/validate-images.sh

# Test instance launch
./infrastructure/images/scripts/test-image.sh --image-id ami-12345
```

## 📚 Advanced Features

### Custom Image Pipelines
```bash
# Create development image with debug tools
./infrastructure/images/scripts/create-images.sh --type dev --debug-tools

# Create minimal image for edge deployments
./infrastructure/images/scripts/create-images.sh --type minimal --size small
```

### Image Versioning
```bash
# Semantic versioning
cyberpot-base-v2.1.0-20240101
cyberpot-enterprise-v2.1.0-20240101

# Environment-specific versions
cyberpot-prod-v2.1.0-20240101
cyberpot-staging-v2.1.0-20240101
```

## 🤝 Contributing

### Adding New Image Types
1. Create Packer template in appropriate provider directory
2. Add provisioning scripts
3. Update image creation script
4. Test thoroughly before production use

### Image Security Updates
1. Monitor base image CVEs
2. Update provisioning scripts for security patches
3. Test updated images in staging
4. Roll out to production with zero-downtime updates

---

## 🎯 Integration with Terraform

Images created by this system are automatically integrated with the existing Terraform configurations:

```hcl
# AWS Example
data "aws_ami" "cyberpot" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    value  = "cyberpot-base-*"
  }

  filter {
    name   = "tag:Environment"
    value  = "production"
  }
}

# Azure Example
data "azurerm_image" "cyberpot" {
  name                = "cyberpot-base"
  resource_group_name = "cyberpot-images"
}

# GCP Example
data "google_compute_image" "cyberpot" {
  family  = "cyberpot-base"
  project = "cyberpot-images"
}
```

**Ready to create and manage custom OS images for CyberPot!** 🚀
