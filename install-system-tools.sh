#!/bin/bash
# CyberPot System Tools Installation Script
# Installs Terraform, Ansible, Packer, and other system tools

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}"
}

warning() {
    echo -e "${YELLOW}WARNING: $*${NC}"
}

error() {
    echo -e "${RED}ERROR: $*${NC}"
    exit 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        "Darwin")
            echo "macos"
            ;;
        "Linux")
            if [ -f /etc/debian_version ]; then
                echo "debian"
            elif [ -f /etc/redhat-release ]; then
                echo "rhel"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Install Terraform
install_terraform() {
    local os=$(detect_os)

    log "Installing Terraform..."

    case $os in
        "macos")
            # Install via Homebrew
            if command -v brew &> /dev/null; then
                brew install terraform
            else
                error "Homebrew not found. Please install Homebrew first."
            fi
            ;;
        "debian")
            # Install via apt
            sudo apt-get update
            sudo apt-get install -y gnupg software-properties-common curl

            # Add HashiCorp GPG key
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

            # Add HashiCorp repository
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

            sudo apt-get update
            sudo apt-get install -y terraform
            ;;
        "rhel")
            # Install via yum/dnf
            sudo dnf install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo dnf install -y terraform
            ;;
        *)
            error "Unsupported OS for automatic Terraform installation"
            ;;
    esac

    log "Terraform installed successfully"
}

# Install Ansible
install_ansible() {
    local os=$(detect_os)

    log "Installing Ansible..."

    case $os in
        "macos")
            # Install via Homebrew
            if command -v brew &> /dev/null; then
                brew install ansible
            else
                error "Homebrew not found. Please install Homebrew first."
            fi
            ;;
        "debian")
            # Install via apt
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt-get install -y ansible
            ;;
        "rhel")
            # Install via pip (EPEL required)
            sudo dnf install -y epel-release
            sudo dnf install -y ansible
            ;;
        *)
            error "Unsupported OS for automatic Ansible installation"
            ;;
    esac

    log "Ansible installed successfully"
}

# Install Packer
install_packer() {
    local os=$(detect_os)

    log "Installing Packer..."

    case $os in
        "macos")
            # Install via Homebrew
            if command -v brew &> /dev/null; then
                brew install packer
            else
                error "Homebrew not found. Please install Homebrew first."
            fi
            ;;
        "debian")
            # Install via apt
            sudo apt-get update
            sudo apt-get install -y gnupg software-properties-common curl

            # Add HashiCorp GPG key
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

            # Add HashiCorp repository
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

            sudo apt-get update
            sudo apt-get install -y packer
            ;;
        "rhel")
            # Install via yum/dnf
            sudo dnf install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo dnf install -y packer
            ;;
        *)
            error "Unsupported OS for automatic Packer installation"
            ;;
    esac

    log "Packer installed successfully"
}

# Install AWS CLI
install_aws_cli() {
    local os=$(detect_os)

    log "Installing AWS CLI..."

    case $os in
        "macos")
            # Install via Homebrew
            if command -v brew &> /dev/null; then
                brew install awscli
            else
                error "Homebrew not found. Please install Homebrew first."
            fi
            ;;
        "debian"|"rhel")
            # Install via official installer
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
            ;;
        *)
            error "Unsupported OS for automatic AWS CLI installation"
            ;;
    esac

    log "AWS CLI installed successfully"
}

# Install Docker
install_docker() {
    local os=$(detect_os)

    log "Installing Docker..."

    case $os in
        "macos")
            # Install via Homebrew
            if command -v brew &> /dev/null; then
                brew install --cask docker
                warning "Docker Desktop installed. Please start Docker Desktop manually."
            else
                error "Homebrew not found. Please install Homebrew first."
            fi
            ;;
        "debian")
            # Install Docker Engine
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release

            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            # Set up repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker $(whoami)

            # Start Docker service
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
        "rhel")
            # Install Docker Engine
            sudo dnf install -y docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $(whoami)
            ;;
        *)
            error "Unsupported OS for automatic Docker installation"
            ;;
    esac

    log "Docker installed successfully"
}

# Install development tools (Python packages)
install_python_deps() {
    log "Installing Python development dependencies..."

    # Upgrade pip
    python3 -m pip install --upgrade pip

    # Install Python development tools
    python3 -m pip install black flake8 pylint mypy autopep8

    log "Python dependencies installed successfully"
}

# Check if tools are already installed
check_existing() {
    local tools=("terraform" "ansible" "packer" "aws" "docker")
    local missing=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        else
            echo "✓ $tool: $(which $tool)"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        warning "Missing tools: ${missing[*]}"
        return 1
    else
        log "All required tools are already installed"
        return 0
    fi
}

# Main installation function
main() {
    echo -e "${GREEN}"
    echo "🛠️  CyberPot System Tools Installation"
    echo "===================================="
    echo -e "${NC}"

    local os=$(detect_os)
    log "Detected OS: $os"

    # Check if tools are already installed
    if check_existing; then
        log "All tools are already installed. No installation needed."
        exit 0
    fi

    # Ask for confirmation
    echo
    echo "This script will install the following tools:"
    echo "  - Terraform (Infrastructure as Code)"
    echo "  - Ansible (Configuration Management)"
    echo "  - Packer (OS Image Creation)"
    echo "  - AWS CLI (Cloud Management)"
    echo "  - Docker (Container Platform)"
    echo "  - Python Development Tools"
    echo
    read -p "Continue with installation? (y/N): " confirm
    echo

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Installation cancelled"
        exit 0
    fi

    # Install tools
    case $os in
        "macos"|"debian"|"rhel")
            install_terraform
            install_ansible
            install_packer
            install_aws_cli
            install_docker
            install_python_deps
            ;;
        *)
            error "Automatic installation not supported for OS: $os"
            echo "Please install the tools manually:"
            echo "  - Terraform: https://www.terraform.io/downloads"
            echo "  - Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
            echo "  - Packer: https://www.packer.io/downloads"
            echo "  - AWS CLI: https://aws.amazon.com/cli/"
            echo "  - Docker: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac

    # Verify installation
    echo
    log "Verifying installation..."
    if check_existing; then
        echo -e "${GREEN}"
        echo "✅ All system tools installed successfully!"
        echo -e "${NC}"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Restart your terminal or run: source ~/.bashrc"
        echo "   2. Test installation: make verify"
        echo "   3. Create your first AMI: make image-create"
        echo ""
        echo "🎯 You're ready to use CyberPot OS Image Management!"
    else
        error "Some tools failed to install. Please check the output above."
        exit 1
    fi
}

# Run main function
main
