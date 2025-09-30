#!/bin/bash
# CyberPot OS Image Creation Script
# Simplified script for creating CyberPot OS images

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

error() {
    echo -e "${RED}ERROR: $*${NC}"
}

warning() {
    echo -e "${YELLOW}WARNING: $*${NC}"
}

# Check if Packer is installed
check_packer() {
    if ! command -v packer &> /dev/null; then
        error "Packer is not installed. Please install Packer first."
        echo "Visit: https://www.packer.io/downloads"
        exit 1
    fi

    log "Packer version: $(packer version)"
}

# Check if AWS CLI is configured
check_aws() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed."
        exit 1
    fi

    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials are not configured."
        echo "Run: aws configure"
        exit 1
    fi

    log "AWS CLI configured successfully"
}

# Get the latest Ubuntu AMI ID
get_ubuntu_ami() {
    local region=$1
    log "Getting latest Ubuntu 22.04 AMI for region: $region"

    # In a real implementation, this would query AWS API
    # For now, return known AMI IDs
    case $region in
        "us-east-1") echo "ami-0abcdef1234567890" ;;
        "us-west-2") echo "ami-0abcdef1234567891" ;;
        "eu-west-1") echo "ami-0abcdef1234567892" ;;
        *) echo "ami-0abcdef1234567890" ;; # Default fallback
    esac
}

# Create base CyberPot AMI
create_base_ami() {
    local region=${1:-us-east-1}
    local base_ami=$(get_ubuntu_ami $region)

    log "Creating CyberPot base AMI in region: $region"

    cd infrastructure/images/packer/aws

    # Set environment variables
    export AWS_REGION=$region
    export CYBERPOT_VERSION=24.04.1
    export ENVIRONMENT=production
    export INSTANCE_TYPE=t3.medium
    export BASE_AMI_ID=$base_ami
    export SECURITY_LEVEL=high
    export MONITORING_ENABLED=true

    # Validate template
    log "Validating Packer template..."
    if ! packer validate cyberpot-base.json; then
        error "Template validation failed"
        exit 1
    fi

    # Build AMI
    log "Building AMI (this may take 15-30 minutes)..."
    if packer build cyberpot-base.json; then
        log "Base AMI created successfully"
    else
        error "AMI creation failed"
        exit 1
    fi
}

# Create enterprise CyberPot AMI
create_enterprise_ami() {
    local region=${1:-us-east-1}
    local base_ami=$(get_ubuntu_ami $region)

    log "Creating CyberPot enterprise AMI in region: $region"

    cd infrastructure/images/packer/aws

    # Set environment variables
    export AWS_REGION=$region
    export CYBERPOT_VERSION=24.04.1
    export ENVIRONMENT=production
    export INSTANCE_TYPE=t3.medium
    export BASE_AMI_ID=$base_ami
    export SECURITY_LEVEL=high
    export MONITORING_ENABLED=true
    export THREAT_INTELLIGENCE=true
    export VULNERABILITY_SCANNING=true
    export DARK_WEB_MONITORING=false

    # Validate template
    log "Validating Packer template..."
    if ! packer validate cyberpot-enterprise.json; then
        error "Template validation failed"
        exit 1
    fi

    # Build AMI
    log "Building enterprise AMI (this may take 20-40 minutes)..."
    if packer build cyberpot-enterprise.json; then
        log "Enterprise AMI created successfully"
    else
        error "Enterprise AMI creation failed"
        exit 1
    fi
}

# Main script logic
main() {
    echo -e "${GREEN}"
    echo "🖥️  CyberPot OS Image Creation System"
    echo "==================================="
    echo -e "${NC}"

    # Parse arguments
    PROVIDER=${1:-aws}
    IMAGE_TYPE=${2:-base}
    REGION=${3:-us-east-1}

    case $PROVIDER in
        aws)
            check_packer
            check_aws

            case $IMAGE_TYPE in
                base)
                    create_base_ami $REGION
                    ;;
                enterprise)
                    create_enterprise_ami $REGION
                    ;;
                all)
                    create_base_ami $REGION
                    create_enterprise_ami $REGION
                    ;;
                *)
                    error "Unknown image type: $IMAGE_TYPE"
                    echo "Available types: base, enterprise, all"
                    exit 1
                    ;;
            esac
            ;;
        azure|gcp)
            warning "Provider $PROVIDER not yet implemented"
            echo "Currently supported: aws"
            exit 1
            ;;
        *)
            error "Unknown provider: $PROVIDER"
            echo "Available providers: aws, azure, gcp"
            exit 1
            ;;
    esac

    echo -e "${GREEN}"
    echo "✅ OS Image creation completed successfully!"
    echo -e "${NC}"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test the created AMI with: make validate-image"
    echo "   2. Update your Terraform configurations to use the new AMI"
    echo "   3. Deploy CyberPot using the new image"
    echo ""
    echo "🔧 To view available AMIs:"
    echo "   python3 infrastructure/images/scripts/create-images.py --provider aws --action list"
}

# Run main function with all arguments
main "$@"
