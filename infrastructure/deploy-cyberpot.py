#!/usr/bin/env python3
"""
CyberPot Deployment Automation Script
Automates the deployment of CyberPot across multiple cloud providers
"""

import argparse
import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
import yaml


class CyberPotDeployer:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.terraform_dir = self.base_dir / "terraform"
        self.ansible_dir = self.base_dir / "ansible"

    def load_config(self, environment="dev"):
        """Load deployment configuration for specified environment"""
        config_file = self.base_dir / "templates" / "deployment_config.py"

        # Import configuration (this would normally be in a separate config file)
        # For now, we'll use a simplified approach
        configs = {
            "dev": {
                "instance_type": {
                    "aws": "t3.medium",
                    "azure": "Standard_B2s",
                    "gcp": "e2-medium",
                },
                "data_volume_size": 128,
                "monitoring": True,
            },
            "prod": {
                "instance_type": {
                    "aws": "t3.large",
                    "azure": "Standard_B4ms",
                    "gcp": "n2-standard-2",
                },
                "data_volume_size": 256,
                "monitoring": True,
            },
        }

        return configs.get(environment, configs["dev"])

    def validate_requirements(self):
        """Validate that all required tools are installed"""
        required_tools = {
            "terraform": "Terraform >= 1.0",
            "ansible": "Ansible >= 2.10",
            "docker": "Docker >= 20.0",
            "git": "Git >= 2.0",
        }

        missing_tools = []

        for tool, version_req in required_tools.items():
            try:
                result = subprocess.run(
                    [tool, "--version"], capture_output=True, text=True, check=True
                )
                print(
                    f"✓ {tool}: {result.stdout.strip().split()[1] if len(result.stdout.strip().split()) > 1 else 'Found'}"
                )
            except (subprocess.CalledProcessError, FileNotFoundError):
                missing_tools.append(f"{tool} ({version_req})")
                print(f"✗ {tool}: Not found")

        if missing_tools:
            print(f"\nMissing required tools: {', '.join(missing_tools)}")
            print("Please install missing tools and try again.")
            return False

        return True

    def deploy_aws(self, config, region="us-east-1"):
        """Deploy CyberPot on AWS"""
        print(f"🚀 Deploying CyberPot to AWS {region}...")

        tf_dir = self.terraform_dir / "aws"

        # Initialize Terraform
        self.run_command("terraform init", cwd=tf_dir)

        # Plan deployment
        plan_cmd = [
            "terraform",
            "plan",
            "-var",
            f"aws_region={region}",
            "-var",
            f"environment={config.get('environment', 'dev')}",
            "-var",
            f"instance_type={config['instance_type']['aws']}",
            "-var",
            f"data_volume_size={config['data_volume_size']}",
            "-out",
            "tfplan",
        ]

        self.run_command(plan_cmd, cwd=tf_dir)

        # Apply deployment
        if input("Apply Terraform plan? (y/N): ").lower() == "y":
            self.run_command(["terraform", "apply", "tfplan"], cwd=tf_dir)

        print("✅ AWS deployment completed!")

    def deploy_azure(self, config, location="East US"):
        """Deploy CyberPot on Azure"""
        print(f"🚀 Deploying CyberPot to Azure {location}...")

        tf_dir = self.terraform_dir / "azure"

        # Initialize Terraform
        self.run_command("terraform init", cwd=tf_dir)

        # Plan deployment
        plan_cmd = [
            "terraform",
            "plan",
            "-var",
            f"azure_location={location}",
            "-var",
            f"environment={config.get('environment', 'dev')}",
            "-var",
            f"vm_size={config['instance_type']['azure']}",
            "-var",
            f"data_disk_size={config['data_volume_size']}",
            "-out",
            "tfplan",
        ]

        self.run_command(plan_cmd, cwd=tf_dir)

        # Apply deployment
        if input("Apply Terraform plan? (y/N): ").lower() == "y":
            self.run_command(["terraform", "apply", "tfplan"], cwd=tf_dir)

        print("✅ Azure deployment completed!")

    def deploy_gcp(self, config, region="us-central1", project_id=None):
        """Deploy CyberPot on GCP"""
        print(f"🚀 Deploying CyberPot to GCP {region}...")

        if not project_id:
            print("❌ GCP project ID is required")
            return

        tf_dir = self.terraform_dir / "gcp"

        # Initialize Terraform
        self.run_command("terraform init", cwd=tf_dir)

        # Plan deployment
        plan_cmd = [
            "terraform",
            "plan",
            "-var",
            f"gcp_project_id={project_id}",
            "-var",
            f"gcp_region={region}",
            "-var",
            f"environment={config.get('environment', 'dev')}",
            "-var",
            f"machine_type={config['instance_type']['gcp']}",
            "-var",
            f"data_disk_size={config['data_volume_size']}",
            "-out",
            "tfplan",
        ]

        self.run_command(plan_cmd, cwd=tf_dir)

        # Apply deployment
        if input("Apply Terraform plan? (y/N): ").lower() == "y":
            self.run_command(["terraform", "apply", "tfplan"], cwd=tf_dir)

        print("✅ GCP deployment completed!")

    def run_ansible_provisioning(self, inventory_file=None):
        """Run Ansible playbooks for server provisioning"""
        print("🔧 Running Ansible provisioning...")

        playbook = self.ansible_dir / "playbooks" / "cyberpot_provisioning.yml"

        if not playbook.exists():
            print(f"❌ Playbook not found: {playbook}")
            return

        cmd = ["ansible-playbook", str(playbook)]

        if inventory_file and Path(inventory_file).exists():
            cmd.extend(["-i", inventory_file])

        # Add verbose output for debugging
        cmd.append("-v")

        self.run_command(cmd, cwd=self.ansible_dir)

        print("✅ Ansible provisioning completed!")

    def run_command(self, cmd, cwd=None, check=True):
        """Run shell command with proper error handling"""
        try:
            if isinstance(cmd, list):
                print(f"Running: {' '.join(cmd)}")
            else:
                print(f"Running: {cmd}")

            result = subprocess.run(
                cmd if isinstance(cmd, list) else cmd.split(),
                cwd=cwd,
                check=check,
                capture_output=True,
                text=True,
            )

            if result.stdout:
                print(result.stdout)

            return result

        except subprocess.CalledProcessError as e:
            print(
                f"❌ Command failed: {' '.join(cmd) if isinstance(cmd, list) else cmd}"
            )
            print(f"Error: {e.stderr}")
            raise

    def generate_deployment_summary(self, config, provider, region):
        """Generate deployment summary report"""
        summary = {
            "deployment_timestamp": datetime.now().isoformat(),
            "provider": provider,
            "region": region,
            "environment": config.get("environment", "dev"),
            "configuration": config,
            "estimated_cost": self.estimate_cost(config, provider),
            "deployment_steps": [
                "Infrastructure provisioning",
                "Security hardening",
                "Docker installation",
                "CyberPot deployment",
                "Configuration setup",
                "Monitoring setup",
                "Verification tests",
            ],
        }

        # Save summary to file
        summary_file = self.base_dir / "deployment_summary.json"
        with open(summary_file, "w") as f:
            json.dump(summary, f, indent=2)

        print(f"📋 Deployment summary saved to: {summary_file}")

        return summary

    def estimate_cost(self, config, provider):
        """Estimate monthly cost for deployment"""
        # Simplified cost estimation - in production this would use provider APIs
        base_costs = {
            "aws": {"t3.medium": 25, "t3.large": 50, "t3.xlarge": 100},
            "azure": {"Standard_B2s": 20, "Standard_B4ms": 40, "Standard_D4s_v3": 80},
            "gcp": {"e2-medium": 20, "n2-standard-2": 45, "n2-standard-4": 90},
        }

        instance_cost = base_costs.get(provider, {}).get(
            config["instance_type"][provider], 25
        )
        storage_cost = config["data_volume_size"] * \
            0.10  # $0.10 per GB per month
        network_cost = 5  # Estimated network costs

        return {
            "monthly_compute": instance_cost,
            "monthly_storage": storage_cost,
            "monthly_network": network_cost,
            "monthly_total": instance_cost + storage_cost + network_cost,
        }

    def create_deployment_documentation(self, config, provider):
        """Create comprehensive deployment documentation"""
        doc_content = f"""# CyberPot Deployment Documentation

## Deployment Summary

- **Deployment Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Provider:** {provider.upper()}
- **Environment:** {config.get('environment', 'dev')}
- **Instance Type:** {config['instance_type'][provider]}

## Configuration Details

### Infrastructure
- Data Volume Size: {config['data_volume_size']} GB
- Monitoring: {'Enabled' if config.get('monitoring') else 'Disabled'}

### Access Information

⚠️  **Access credentials will be provided after deployment completion**

### Management Commands

#### SSH Access
```bash
# AWS
ssh -i <key-file> ubuntu@<public-ip>

# Azure
ssh -i <key-file> cyberpotadmin@<public-ip>

# GCP
gcloud compute ssh <instance-name> --zone=<zone>
```

#### CyberPot Management
```bash
# Check status
sudo systemctl status cyberpot

# View logs
sudo docker compose logs

# Restart services
sudo systemctl restart cyberpot
```

## Security Considerations

- All passwords are randomly generated and stored securely
- SSH access uses key-based authentication only
- Firewall restricts access to necessary ports only
- All data is encrypted at rest

## Maintenance

### Regular Tasks
- Daily: Log rotation and cleanup
- Weekly: Security updates
- Monthly: Full system backup

### Monitoring
- System metrics: CPU, memory, disk usage
- CyberPot metrics: Honeypot activity, attack patterns
- Security events: Failed logins, suspicious activity

## Troubleshooting

### Common Issues

1. **Service won't start**
   - Check Docker service status
   - Verify disk space availability
   - Check system logs: `journalctl -u cyberpot`

2. **Network connectivity issues**
   - Verify firewall configuration
   - Check security group rules
   - Test network connectivity

3. **High resource usage**
   - Monitor Docker container usage
   - Check for memory leaks
   - Consider scaling up instance type

## Support

For issues and questions:
- Check the CyberPot documentation: https://github.com/khulnasoft/cyberpot
- Open issues on GitHub: https://github.com/khulnasoft/cyberpot/issues
- Join discussions: https://github.com/khulnasoft/cyberpot/discussions

---
*Generated by CyberPot Deployment Automation*
"""

        doc_file = (
            self.base_dir
            / f"deployment_docs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        )
        with open(doc_file, "w") as f:
            f.write(doc_content)

        print(f"📚 Deployment documentation created: {doc_file}")


def main():
    parser = argparse.ArgumentParser(
        description="CyberPot Deployment Automation")
    parser.add_argument(
        "--provider",
        choices=["aws", "azure", "gcp"],
        required=True,
        help="Cloud provider",
    )
    parser.add_argument(
        "--environment",
        choices=["dev", "staging", "prod"],
        default="dev",
        help="Deployment environment",
    )
    parser.add_argument("--region", help="Cloud region")
    parser.add_argument(
        "--project-id", help="GCP project ID (required for GCP)")
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Only verify requirements, do not deploy",
    )
    parser.add_argument("--ansible-inventory", help="Ansible inventory file")

    args = parser.parse_args()

    deployer = CyberPotDeployer()

    # Set default regions based on provider
    if not args.region:
        if args.provider == "aws":
            args.region = "us-east-1"
        elif args.provider == "azure":
            args.region = "East US"
        elif args.provider == "gcp":
            args.region = "us-central1"

    print("🚀 CyberPot Deployment Automation")
    print(f"Provider: {args.provider}")
    print(f"Environment: {args.environment}")
    print(f"Region: {args.region}")

    # Validate requirements
    if not deployer.validate_requirements():
        sys.exit(1)

    if args.verify_only:
        print("✅ All requirements verified successfully!")
        return

    # Load configuration
    config = deployer.load_config(args.environment)
    print(f"📋 Loaded configuration for {args.environment} environment")

    # Deploy based on provider
    if args.provider == "aws":
        deployer.deploy_aws(config, args.region)
    elif args.provider == "azure":
        deployer.deploy_azure(config, args.region)
    elif args.provider == "gcp":
        if not args.project_id:
            print("❌ GCP project ID is required for GCP deployments")
            sys.exit(1)
        deployer.deploy_gcp(config, args.region, args.project_id)

    # Generate deployment summary and documentation
    deployer.generate_deployment_summary(config, args.provider, args.region)
    deployer.create_deployment_documentation(config, args.provider)

    # Run Ansible provisioning if inventory provided
    if args.ansible_inventory:
        deployer.run_ansible_provisioning(args.ansible_inventory)

    print("🎉 CyberPot deployment completed successfully!")


if __name__ == "__main__":
    main()
