# 🚀 CyberPot Development & Deployment Guide

## 📋 Overview

This Makefile provides a comprehensive set of commands for developing, building, formatting, testing, and deploying CyberPot across multiple environments and cloud providers.

## 🎯 Quick Start

```bash
# Set up development environment
make dev-setup

# Deploy CyberPot (basic)
make deploy

# Deploy Enterprise platform
make enterprise-deploy

# Run health check
make health-check
```

## 📂 Project Structure

```
cyberpot/
├── Makefile                    # This file - all commands
├── infrastructure/             # IaC (Terraform, Ansible)
│   ├── terraform/             # Multi-cloud infrastructure
│   └── ansible/               # Server provisioning
├── enterprise/                # Enterprise platform
│   ├── config/                # Centralized configuration
│   ├── security-tools/        # Advanced security tools
│   └── deploy-enterprise.py   # Enterprise deployment
├── docker/                    # Docker configurations
├── compose/                   # Docker Compose files
└── logs/                      # Log files
    reports/                   # Deployment reports
```

## 🔧 Development Commands

### Environment Setup
```bash
make setup          # Complete setup (deps + dev env)
make dev-setup      # Create development directories
make install-deps   # Install Python tools (black, flake8, etc.)
make clean          # Clean build artifacts
```

### Code Quality
```bash
make format         # Format Python and Terraform code
make lint           # Lint code for issues
make test           # Run tests
make build          # Format, lint, and test
```

## 🚀 Deployment Commands

### Basic Deployment
```bash
make deploy         # Deploy using shell script
make deploy-aws     # Deploy to AWS
make deploy-azure   # Deploy to Azure
make deploy-gcp     # Deploy to GCP
```

### Enterprise Deployment
```bash
make deploy-enterprise     # Deploy enterprise platform
make enterprise-setup      # Set up enterprise environment
make enterprise-deploy     # Deploy with all features
make enterprise-health     # Enterprise health check
```

### Infrastructure Management
```bash
make terraform-init        # Initialize Terraform
make terraform-plan        # Plan infrastructure
make terraform-apply       # Apply infrastructure
make terraform-destroy     # Destroy infrastructure (CAUTION!)
make ansible-provision     # Run Ansible provisioning
```

## 🔍 Verification & Monitoring

### Health Checks
```bash
make verify         # Verify deployment requirements
make health-check   # Basic health check
make enterprise-health # Enterprise health check
make capabilities   # Show enterprise features
```

### Security Assessment
```bash
make security-scan         # Run security scan
make vulnerability-scan    # Vulnerability assessment
make threat-intel         # Collect threat intelligence
make forensics           # Digital forensics analysis
```

## 🐳 Docker Commands

```bash
make docker-build   # Build Docker images
make docker-up      # Start containers
make docker-down    # Stop containers
make docker-logs    # View container logs
```

## 📋 Workflows

### Quick Development Cycle
```bash
make dev            # Set up dev env, format, and lint
```

### Production Deployment
```bash
make prod           # Build and deploy enterprise
```

### Complete Security Assessment
```bash
make security       # Run all security tools
```

### Full System Check
```bash
make check          # Health check + capabilities + verify
```

## 🎯 Environment-Specific Commands

### Development Environment
```bash
make dev-setup      # Set up development
make qd             # Quick deploy to dev
```

### Enterprise Environment
```bash
make enterprise-all # Complete enterprise workflow
make qe             # Quick enterprise deploy
```

## 📊 Advanced Commands

```bash
make monitoring     # Set up monitoring stack
make backup         # Create system backup
make restore        # Restore from backup
make docs           # Build documentation
make logs           # View recent logs
make status         # Show system status
make info           # Show project information
```

## 🔧 Command Categories

### 📋 **General Commands**
- `help` - Show help message
- `setup` - Complete environment setup
- `clean` - Clean build artifacts
- `install-deps` - Install development dependencies

### 🔧 **Development Commands**
- `dev-setup` - Set up development environment
- `format` - Format code (Python, Terraform)
- `lint` - Lint code for issues
- `test` - Run tests
- `build` - Complete build process

### 🏗️ **Deployment Commands**
- `deploy` - Deploy CyberPot (basic)
- `deploy-aws` - Deploy to AWS
- `deploy-azure` - Deploy to Azure
- `deploy-gcp` - Deploy to GCP
- `deploy-enterprise` - Deploy enterprise platform

### 🔍 **Verification Commands**
- `verify` - Verify deployment requirements
- `health-check` - Run health check
- `capabilities` - Show enterprise capabilities
- `security-scan` - Run security scan

### 🛠️ **Enterprise Commands**
- `enterprise-setup` - Set up enterprise environment
- `enterprise-deploy` - Deploy enterprise features
- `enterprise-health` - Enterprise health check
- `threat-intel` - Collect threat intelligence
- `vulnerability-scan` - Run vulnerability scan
- `forensics` - Run digital forensics

### 🐳 **Docker Commands**
- `docker-build` - Build Docker images
- `docker-up` - Start Docker containers
- `docker-down` - Stop Docker containers

### 📚 **Infrastructure Commands**
- `terraform-init` - Initialize Terraform
- `terraform-plan` - Plan Terraform deployment
- `terraform-apply` - Apply Terraform deployment
- `terraform-destroy` - Destroy Terraform resources
- `ansible-provision` - Run Ansible provisioning

## 🎨 Development Workflow

### Daily Development
```bash
make dev-setup      # Set up environment
make format         # Format code
make lint           # Check for issues
make test           # Run tests
```

### Feature Development
```bash
make dev            # Quick development cycle
# Make your changes
make test           # Test changes
make deploy         # Deploy for testing
```

### Release Process
```bash
make build          # Ensure code quality
make deploy-enterprise  # Deploy to production
make health-check   # Verify deployment
make security       # Run security assessment
```

## 🔒 Security Workflows

### Threat Assessment
```bash
make threat-intel         # Collect threat intelligence
make vulnerability-scan   # Scan for vulnerabilities
make security-scan        # Run security scan
make forensics           # Analyze evidence
```

### Compliance Verification
```bash
make enterprise-health   # Check compliance status
make capabilities        # Review security features
make verify              # Verify requirements
```

## 📈 Monitoring & Maintenance

### Daily Monitoring
```bash
make health-check   # Check system health
make logs           # Review recent logs
make status         # Show system status
```

### Weekly Maintenance
```bash
make security       # Complete security assessment
make backup         # Create system backup
make clean          # Clean temporary files
```

### Monthly Reviews
```bash
make enterprise-all # Complete enterprise workflow
make check          # Full system verification
make info           # Project status review
```

## 🚨 Troubleshooting

### Common Issues

**Build Errors:**
```bash
make clean          # Clean and retry
make install-deps   # Ensure dependencies
make build          # Retry build
```

**Deployment Issues:**
```bash
make verify         # Check requirements
make terraform-init # Reinitialize
make health-check   # Diagnose issues
```

**Permission Issues:**
```bash
chmod +x deploy.sh  # Fix script permissions
make install-deps   # Install with sudo if needed
```

## 📚 Documentation

- **README.md** - Main project documentation
- **enterprise/README.md** - Enterprise platform guide
- **infrastructure/README.md** - Infrastructure documentation
- **SECURITY.md** - Security considerations

## 🤝 Contributing

1. Set up development environment: `make dev-setup`
2. Make your changes
3. Format code: `make format`
4. Run tests: `make test`
5. Test deployment: `make deploy`
6. Submit pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review the logs: `make logs`
- Run health check: `make health-check`
- Check project info: `make info`

---

*Generated by CyberPot Development Makefile*
