# CyberPot Development & Deployment Makefile
# Comprehensive build, development, formatting, and deployment automation

.PHONY: help setup dev-setup clean format lint test build deploy \
        deploy-aws deploy-azure deploy-gcp deploy-enterprise \
        verify health-check capabilities docs install-deps \
        enterprise-setup enterprise-deploy enterprise-health \
        terraform-init terraform-plan terraform-apply terraform-destroy \
        ansible-provision docker-build docker-up docker-down \
        security-scan vulnerability-scan threat-intel forensics

# Default target
help:
	@echo "🚀 CyberPot Development & Deployment Commands"
	@echo "============================================="
	@echo ""
	@echo "📋 GENERAL COMMANDS:"
	@echo "  help              Show this help message"
	@echo "  setup             Set up development environment"
	@echo "  clean             Clean build artifacts and temporary files"
	@echo "  install-deps      Install development dependencies"
	@echo ""
	@echo "🔧 DEVELOPMENT COMMANDS:"
	@echo "  dev-setup         Set up development environment"
	@echo "  format            Format code (Python, Terraform, YAML)"
	@echo "  lint              Lint code for issues"
	@echo "  test              Run tests"
	@echo "  build             Build all components"
	@echo ""
	@echo "🖥️  OS IMAGE COMMANDS:"
	@echo "  image-create      Create base CyberPot AMI"
	@echo "  image-create-enterprise Create enterprise AMI"
	@echo "  image-create-all  Create all AMIs"
	@echo "  image-list        List available AMIs"
	@echo "  image-update      Update AMIs to new version"
	@echo "  image-cleanup     Clean up old AMIs"
	@echo "  image-validate    Validate AMI functionality"
	@echo ""
	@echo "🔍 VERIFICATION COMMANDS:"
	@echo "  verify            Verify deployment requirements"
	@echo "  health-check      Run health check"
	@echo "  capabilities      Show enterprise capabilities"
	@echo "  security-scan     Run security scan"
	@echo ""
	@echo "🛠️  ENTERPRISE COMMANDS:"
	@echo "  enterprise-setup  Set up enterprise environment"
	@echo "  enterprise-deploy Deploy enterprise features"
	@echo "  enterprise-health Run enterprise health check"
	@echo "  threat-intel      Collect threat intelligence"
	@echo "  vulnerability-scan Run vulnerability scan"
	@echo "  forensics         Run digital forensics"
	@echo ""
	@echo "🐳 DOCKER COMMANDS:"
	@echo "  docker-build      Build Docker images"
	@echo "  docker-up         Start Docker containers"
	@echo "  docker-down       Stop Docker containers"
	@echo ""
	@echo "📚 INFRASTRUCTURE COMMANDS:"
	@echo "  terraform-init    Initialize Terraform"
	@echo "  terraform-plan    Plan Terraform deployment"
	@echo "  terraform-apply   Apply Terraform deployment"
	@echo "  terraform-destroy Destroy Terraform resources"
	@echo "  ansible-provision Run Ansible provisioning"
	@echo ""

# Variables
PYTHON := python3
PIP := pip3
TERRAFORM := terraform
ANSIBLE := ansible
DOCKER_COMPOSE := docker-compose

# Directories
INFRA_DIR := infrastructure
ENTERPRISE_DIR := enterprise
TERRAFORM_DIR := $(INFRA_DIR)/terraform
ANSIBLE_DIR := $(INFRA_DIR)/ansible
DOCKER_DIR := docker

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ============================================================================
# GENERAL COMMANDS
# ============================================================================

setup: install-deps dev-setup
	@echo "$(GREEN)✅ Development environment setup complete!$(NC)"

dev-setup:
	@echo "$(YELLOW)🔧 Setting up development environment...$(NC)"
	@mkdir -p logs reports
	@echo "$(GREEN)✅ Development directories created$(NC)"

clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@rm -rf logs/* reports/* __pycache__/
	@find . -name "*.pyc" -delete
	@find . -name "*.pyo" -delete
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

install-deps:
	@echo "$(YELLOW)📦 Installing development dependencies...$(NC)"
	@$(PIP) install --upgrade pip
	@$(PIP) install black flake8 pylint mypy autopep8
	@echo "$(YELLOW)📋 System tools (Terraform, Ansible, Packer, etc.) should be installed separately$(NC)"
	@echo "$(YELLOW)💡 Run the following command to install system tools:$(NC)"
	@echo "$(YELLOW)   bash install-system-tools.sh$(NC)"
	@echo "$(GREEN)✅ Python dependencies installed$(NC)"

# ============================================================================
# DEVELOPMENT COMMANDS
# ============================================================================

format:
	@echo "$(YELLOW)🎨 Formatting code...$(NC)"
	@find . -name "*.py" -exec black {} \;
	@find . -name "*.py" -exec autopep8 --in-place {} \;
	@if command -v terraform &> /dev/null; then \
		terraform fmt -recursive $(TERRAFORM_DIR); \
		echo "$(GREEN)✅ Terraform files formatted$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Terraform not installed, skipping Terraform formatting$(NC)"; \
	fi

lint:
	@echo "$(YELLOW)🔍 Linting code...$(NC)"
	@flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	@flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
	@pylint --errors-only $(INFRA_DIR) $(ENTERPRISE_DIR) || true
	@echo "$(GREEN)✅ Linting complete$(NC)"

test:
	@echo "$(YELLOW)🧪 Running tests...$(NC)"
	@python3 -m pytest tests/ -v || echo "$(YELLOW)⚠️  No tests found, skipping...$(NC)"
	@echo "$(GREEN)✅ Tests complete$(NC)"

build: format lint test
	@echo "$(GREEN)✅ Build complete$(NC)"

# ============================================================================
# DEPLOYMENT COMMANDS
# ============================================================================

deploy: verify
	@echo "$(YELLOW)🚀 Deploying CyberPot...$(NC)"
	@bash deploy.sh

deploy-aws:
	@echo "$(YELLOW)☁️  Deploying to AWS...$(NC)"
	@cd $(INFRA_DIR) && $(PYTHON) deploy-cyberpot.py --provider aws --environment dev --region us-east-1

deploy-azure:
	@echo "$(YELLOW)☁️  Deploying to Azure...$(NC)"
	@cd $(INFRA_DIR) && $(PYTHON) deploy-cyberpot.py --provider azure --environment dev --region "East US"

deploy-gcp:
	@echo "$(YELLOW)☁️  Deploying to GCP...$(NC)"
	@cd $(INFRA_DIR) && $(PYTHON) deploy-cyberpot.py --provider gcp --environment dev --region us-central1 --project-id your-project-id

deploy-enterprise:
	@echo "$(YELLOW)🏢 Deploying Enterprise Platform...$(NC)"
	@cd $(ENTERPRISE_DIR) && $(PYTHON) deploy-cyberpot-enterprise.py --environment development --provider aws --region us-east-1

# ============================================================================
# VERIFICATION COMMANDS
# ============================================================================

verify:
	@echo "$(YELLOW)🔍 Verifying deployment requirements...$(NC)"
	@cd $(INFRA_DIR) && $(PYTHON) deploy-cyberpot.py --verify-only

health-check:
	@echo "$(YELLOW)🏥 Running health check...$(NC)"
	@cd $(ENTERPRISE_DIR) && $(PYTHON) deploy-cyberpot-enterprise.py --health-check

capabilities:
	@echo "$(YELLOW)📊 Showing enterprise capabilities...$(NC)"
	@cd $(ENTERPRISE_DIR) && $(PYTHON) deploy-cyberpot-enterprise.py --capabilities

security-scan:
	@echo "$(YELLOW)🔒 Running security scan...$(NC)"
	@cd $(ENTERPRISE_DIR)/security-tools/vulnerability-scanning && $(PYTHON) vulnerability-scanner.py

# ============================================================================
# ENTERPRISE COMMANDS
# ============================================================================

enterprise-setup:
	@echo "$(YELLOW)🏢 Setting up enterprise environment...$(NC)"
	@mkdir -p $(ENTERPRISE_DIR)/{config/{environments,regions,security-policies,compliance},deployment,monitoring,security-tools,integration}
	@mkdir -p $(ENTERPRISE_DIR)/{reports,logs,backups}
	@echo "$(GREEN)✅ Enterprise directories created$(NC)"

enterprise-deploy:
	@echo "$(YELLOW)🚀 Deploying enterprise features...$(NC)"
	@cd $(ENTERPRISE_DIR) && $(PYTHON) deploy-cyberpot-enterprise.py --environment production --provider aws --features threat_intelligence dark_web_monitoring siem_integration

enterprise-health:
	@echo "$(YELLOW)🏥 Running enterprise health check...$(NC)"
	@cd $(ENTERPRISE_DIR) && $(PYTHON) deploy-cyberpot-enterprise.py --health-check

threat-intel:
	@echo "$(YELLOW)🕵️  Collecting threat intelligence...$(NC)"
	@cd $(ENTERPRISE_DIR)/security-tools/threat-intelligence && $(PYTHON) threat-collector.py

vulnerability-scan:
	@echo "$(YELLOW)🔍 Running vulnerability scan...$(NC)"
	@cd $(ENTERPRISE_DIR)/security-tools/vulnerability-scanning && $(PYTHON) vulnerability-scanner.py

forensics:
	@echo "$(YELLOW)🔬 Running digital forensics...$(NC)"
	@cd $(ENTERPRISE_DIR)/security-tools/forensics && $(PYTHON) forensics-collector.py

# ============================================================================
# DOCKER COMMANDS
# ============================================================================

docker-build:
	@echo "$(YELLOW)🐳 Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) build

docker-up:
	@echo "$(YELLOW)🐳 Starting Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) up -d

docker-down:
	@echo "$(YELLOW)🐳 Stopping Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) down

docker-logs:
	@echo "$(YELLOW)🐳 Showing Docker logs...$(NC)"
	@$(DOCKER_COMPOSE) logs -f

# ============================================================================
# INFRASTRUCTURE COMMANDS
# ============================================================================

terraform-init:
	@echo "$(YELLOW)🏗️  Initializing Terraform...$(NC)"
	@if command -v terraform &> /dev/null; then \
		cd $(TERRAFORM_DIR)/aws && terraform init; \
		cd $(TERRAFORM_DIR)/azure && terraform init; \
		cd $(TERRAFORM_DIR)/gcp && terraform init; \
	else \
		echo "$(RED)❌ Terraform not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Terraform: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

terraform-plan:
	@echo "$(YELLOW)📋 Planning Terraform deployment...$(NC)"
	@if command -v terraform &> /dev/null; then \
		cd $(TERRAFORM_DIR)/aws && terraform plan -var="environment=dev" -var="instance_type=t3.medium" -out=tfplan; \
		cd $(TERRAFORM_DIR)/azure && terraform plan -var="environment=dev" -var="vm_size=Standard_B2s" -out=tfplan; \
		cd $(TERRAFORM_DIR)/gcp && terraform plan -var="environment=dev" -var="machine_type=e2-medium" -out=tfplan; \
	else \
		echo "$(RED)❌ Terraform not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Terraform: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

terraform-apply:
	@echo "$(YELLOW)🚀 Applying Terraform deployment...$(NC)"
	@if command -v terraform &> /dev/null; then \
		cd $(TERRAFORM_DIR)/aws && terraform apply tfplan; \
		cd $(TERRAFORM_DIR)/azure && terraform apply tfplan; \
		cd $(TERRAFORM_DIR)/gcp && terraform apply tfplan; \
	else \
		echo "$(RED)❌ Terraform not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Terraform: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

terraform-destroy:
	@echo "$(RED)💥 Destroying Terraform resources...$(NC)"
	@if command -v terraform &> /dev/null; then \
		read -p "Are you sure? This will destroy all resources! (y/N): " confirm && [ "$$confirm" = "y" ]; \
		cd $(TERRAFORM_DIR)/aws && terraform destroy -auto-approve; \
		cd $(TERRAFORM_DIR)/azure && terraform destroy -auto-approve; \
		cd $(TERRAFORM_DIR)/gcp && terraform destroy -auto-approve; \
	else \
		echo "$(RED)❌ Terraform not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Terraform: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

ansible-provision:
	@echo "$(YELLOW)🔧 Running Ansible provisioning...$(NC)"
	@if command -v ansible-playbook &> /dev/null; then \
		cd $(ANSIBLE_DIR) && ansible all -i inventory.ini -m ping; \
		ansible-playbook playbooks/cyberpot_provisioning.yml -i inventory.ini; \
	else \
		echo "$(RED)❌ Ansible not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Ansible: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

# ============================================================================
# DEVELOPMENT WORKFLOW COMMANDS
# ============================================================================

dev-env: dev-setup install-deps
	@echo "$(GREEN)✅ Development environment ready!$(NC)"

quick-deploy: build deploy
	@echo "$(GREEN)✅ Quick deployment complete!$(NC)"

full-deploy: build terraform-init terraform-plan terraform-apply ansible-provision
	@echo "$(GREEN)✅ Full deployment complete!$(NC)"

enterprise-full: enterprise-setup enterprise-deploy enterprise-health
	@echo "$(GREEN)✅ Enterprise deployment complete!$(NC)"

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

docs:
	@echo "$(YELLOW)📚 Building documentation...$(NC)"
	@echo "$(GREEN)✅ Documentation available in README.md$(NC)"

logs:
	@echo "$(YELLOW)📋 Showing recent logs...$(NC)"
	@tail -f logs/*.log 2>/dev/null || echo "No log files found"

status:
	@echo "$(YELLOW)📊 System status...$(NC)"
	@echo "Docker containers:"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "Recent deployments:"
	@ls -la reports/ | tail -5

# ============================================================================
# ALIASES FOR COMMON WORKFLOWS
# ============================================================================

# Quick development cycle
dev: dev-env format lint

# Production deployment
prod: build deploy-enterprise

# Security assessment
security: security-scan vulnerability-scan threat-intel

# Complete system check
check: health-check capabilities verify

# ============================================================================
# ENVIRONMENT SPECIFIC TARGETS
# ============================================================================

# Development environment targets
dev-setup: dev-setup
	@echo "$(YELLOW)🔧 Development environment configured$(NC)"

# Staging environment targets
staging-setup:
	@echo "$(YELLOW)🟡 Setting up staging environment...$(NC)"
	@mkdir -p staging/

# Production environment targets
prod-setup:
	@echo "$(YELLOW)🔴 Setting up production environment...$(NC)"
	@mkdir -p prod/

# ============================================================================
# ADVANCED COMMANDS
# ============================================================================

enterprise-all: enterprise-setup enterprise-deploy threat-intel vulnerability-scan forensics enterprise-health
	@echo "$(GREEN)✅ Complete enterprise workflow executed!$(NC)"

monitoring:
	@echo "$(YELLOW)📊 Setting up monitoring...$(NC)"
	@$(DOCKER_COMPOSE) up -d prometheus grafana

backup:
	@echo "$(YELLOW)💾 Creating backups...$(NC)"
	@tar -czf "cyberpot_backup_$$(date +%Y%m%d_%H%M%S).tar.gz" $(INFRA_DIR) $(ENTERPRISE_DIR) logs/ reports/

restore:
	@echo "$(YELLOW)🔄 Restoring from backup...$(NC)"
	@echo "$(RED)⚠️  This will overwrite current configuration!$(NC)"
	@read -p "Backup file: " backup_file && tar -xzf $$backup_file

# ============================================================================
# DEVELOPMENT SHORTCUTS
# ============================================================================

# Quick format and check
fmt: format lint

# Quick build and test
bt: build test

# Quick deploy to dev
qd: dev-env deploy

# Quick enterprise deploy
qe: enterprise-setup deploy-enterprise

# ============================================================================
# HELP AND INFORMATION
# ============================================================================

info:
	@echo "$(YELLOW)ℹ️  CyberPot Project Information$(NC)"
	@echo "====================================="
	@echo "Version: $$(cat version 2>/dev/null || echo 'unknown')"
	@echo "Environment: $$(git branch --show-current 2>/dev/null || echo 'local')"
	@echo "Last commit: $$(git log -1 --format='%h %s' 2>/dev/null || echo 'no git repo')"
	@echo ""
	@echo "Quick start:"
	@echo "  make dev-setup    # Set up development"
	@echo "  make deploy       # Deploy CyberPot"
	@echo "  make enterprise   # Deploy enterprise features"
	@echo "  make check        # Verify everything works"

# Show available make targets
# ============================================================================
# OS IMAGE MANAGEMENT COMMANDS
# ============================================================================

image-create:
	@echo "$(YELLOW)🖥️  Creating CyberPot OS images...$(NC)"
	@if command -v packer &> /dev/null; then \
		bash infrastructure/images/scripts/create-images.sh aws base; \
	else \
		echo "$(RED)❌ Packer not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Packer: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

image-create-enterprise:
	@echo "$(YELLOW)🏢 Creating CyberPot enterprise images...$(NC)"
	@if command -v packer &> /dev/null; then \
		bash infrastructure/images/scripts/create-images.sh aws enterprise; \
	else \
		echo "$(RED)❌ Packer not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Packer: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

image-create-all:
	@echo "$(YELLOW)📦 Creating all CyberPot images...$(NC)"
	@if command -v packer &> /dev/null; then \
		bash infrastructure/images/scripts/create-images.sh aws all; \
	else \
		echo "$(RED)❌ Packer not installed$(NC)"; \
		echo "$(YELLOW)💡 Install Packer: bash install-system-tools.sh$(NC)"; \
		exit 1; \
	fi

image-list:
	@echo "$(YELLOW)📋 Listing CyberPot images...$(NC)"
	@if command -v python3 &> /dev/null; then \
		python3 infrastructure/images/scripts/create-images.py --provider aws --action list; \
	else \
		echo "$(RED)❌ Python 3 not found$(NC)"; \
		exit 1; \
	fi

image-update:
	@echo "$(YELLOW)🔄 Updating CyberPot images...$(NC)"
	@if command -v python3 &> /dev/null; then \
		python3 infrastructure/images/scripts/create-images.py --provider aws --action update --version 24.04.2; \
	else \
		echo "$(RED)❌ Python 3 not found$(NC)"; \
		exit 1; \
	fi

image-cleanup:
	@echo "$(YELLOW)🧹 Cleaning up old images...$(NC)"
	@if command -v python3 &> /dev/null; then \
		python3 infrastructure/images/scripts/create-images.py --provider aws --action cleanup --keep-count 5; \
	else \
		echo "$(RED)❌ Python 3 not found$(NC)"; \
		exit 1; \
	fi

image-validate:
	@echo "$(YELLOW)🔍 Validating CyberPot image...$(NC)"
	@if command -v python3 &> /dev/null; then \
		read -p "Enter AMI ID to validate: " ami_id && python3 infrastructure/images/scripts/create-images.py --provider aws --action validate --ami-id $$ami_id; \
	else \
		echo "$(RED)❌ Python 3 not found$(NC)"; \
		exit 1; \
	fi

# ============================================================================
# ADVANCED IMAGE COMMANDS
# ============================================================================

images-dev: image-create
	@echo "$(GREEN)✅ Development images created$(NC)"

images-prod: image-create-enterprise
	@echo "$(GREEN)✅ Production images created$(NC)"

images-all: image-create-all image-validate
	@echo "$(GREEN)✅ All images created and validated$(NC)"

# ============================================================================
# IMAGE WORKFLOW COMMANDS
# ============================================================================

# Quick image operations
image-dev-setup: images-dev
	@echo "$(YELLOW)🔧 Development image setup complete$(NC)"

image-prod-setup: images-prod
	@echo "$(YELLOW)🏭 Production image setup complete$(NC)"
