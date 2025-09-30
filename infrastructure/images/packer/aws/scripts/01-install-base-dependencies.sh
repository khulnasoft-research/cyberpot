#!/bin/bash
# CyberPot AWS AMI Provisioning Script - Base Dependencies
# This script installs basic dependencies required for CyberPot

set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error handling
handle_error() {
    log "ERROR: $*"
    exit 1
}

trap 'handle_error "Script failed at line $LINENO"' ERR

log "Starting CyberPot base dependencies installation..."

# Update package index
log "Updating package index..."
sudo apt-get update -y

# Install essential packages
log "Installing essential packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    htop \
    vim \
    wget \
    jq \
    python3-pip \
    ufw \
    fail2ban \
    auditd \
    rkhunter

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
log "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install AWS CLI for monitoring and management
log "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Install CloudWatch agent for monitoring
log "Installing CloudWatch agent..."
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure basic firewall
log "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (CyberPot uses port 64295)
sudo ufw allow 64295/tcp

# Allow CyberPot Web UI (port 64297)
sudo ufw allow 64297/tcp

# Allow honeypot ports (comprehensive range)
sudo ufw allow 1:64000/tcp
sudo ufw allow 1:64000/udp

# Allow established connections
sudo ufw allow out on all

# Enable firewall
sudo ufw --force enable

# Install security tools
log "Installing security tools..."
sudo apt-get install -y \
    clamav \
    clamav-daemon \
    aide \
    logwatch \
    apparmor \
    apparmor-utils

# Configure audit daemon
log "Configuring audit daemon..."
sudo systemctl enable auditd
sudo systemctl start auditd

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create CyberPot directories
log "Creating CyberPot directories..."
sudo mkdir -p /home/ubuntu/cyberpot
sudo mkdir -p /home/ubuntu/cyberpot/data
sudo mkdir -p /home/ubuntu/cyberpot/backups
sudo mkdir -p /home/ubuntu/cyberpot/logs

# Set proper ownership
sudo chown -R ubuntu:ubuntu /home/ubuntu/cyberpot

# Create log directories with proper permissions
sudo mkdir -p /var/log/cyberpot
sudo chown -R ubuntu:ubuntu /var/log/cyberpot

# Install Python dependencies for CyberPot management
log "Installing Python dependencies..."
sudo pip3 install boto3 requests python-dateutil

# Configure log rotation
log "Configuring log rotation..."
sudo tee /etc/logrotate.d/cyberpot << EOF
/var/log/cyberpot/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}

/home/ubuntu/cyberpot/data/cyberpotinit.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOF

# Set up daily maintenance cron job
log "Setting up maintenance cron jobs..."
sudo tee /etc/cron.daily/cyberpot-maintenance << 'EOF'
#!/bin/bash
# CyberPot daily maintenance script

# Clean up old Docker images and containers
docker system prune -f

# Update virus definitions
freshclam

# Run rkhunter check
rkhunter --check --sk

# Update audit rules
sudo service auditd reload

# Clean up old log files
find /var/log -name "*.log" -type f -mtime +30 -delete

# Clean up temporary files
find /tmp -type f -mtime +7 -delete

exit 0
EOF

sudo chmod +x /etc/cron.daily/cyberpot-maintenance

# Create CyberPot configuration template
log "Creating CyberPot configuration template..."
sudo tee /home/ubuntu/cyberpot/.env.template << 'EOF'
# CyberPot Configuration Template
# Copy this file to .env and customize as needed

# Web usernames and passwords (will be set during deployment)
WEB_USER=
LS_WEB_USER=

# CyberPot Blackhole
CYBERPOT_BLACKHOLE=DISABLED

# CyberPot Persistence
CYBERPOT_PERSISTENCE=on

# CyberPot Type
CYBERPOT_TYPE=HIVE

# CyberPot AttackMap Text Output
CYBERPOT_ATTACKMAP_TEXT=ENABLED

# CyberPot AttackMap Text Output Timezone
CYBERPOT_ATTACKMAP_TEXT_TIMEZONE=UTC

# Docker Configuration
CYBERPOT_REPO=ghcr.io/khulnasoft
CYBERPOT_VERSION=24.04.1
CYBERPOT_PULL_POLICY=always
CYBERPOT_DATA_PATH=./data

# OSType
CYBERPOT_OSTYPE=linux

# Environment
CYBERPOT_ENVIRONMENT=production
EOF

sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/.env.template

# Create startup script for CyberPot initialization
log "Creating CyberPot startup script..."
sudo tee /home/ubuntu/cyberpot/start-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot startup script

cd /home/ubuntu/cyberpot

# Check if .env file exists
if [ ! -f .env ]; then
    echo "CyberPot configuration (.env) not found!"
    exit 1
fi

# Start CyberPot using Docker Compose
docker compose up -d

# Wait for services to be ready
sleep 30

# Verify services are running
if docker compose ps | grep -q "Up"; then
    echo "CyberPot services started successfully"
    exit 0
else
    echo "Failed to start CyberPot services"
    exit 1
fi
EOF

sudo chmod +x /home/ubuntu/cyberpot/start-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/start-cyberpot.sh

# Create systemd service for CyberPot
log "Creating CyberPot systemd service..."
sudo tee /etc/systemd/system/cyberpot.service << EOF
[Unit]
Description=CyberPot Honeypot Platform
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/cyberpot
ExecStart=/home/ubuntu/cyberpot/start-cyberpot.sh
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300
TimeoutStopSec=60
User=ubuntu
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# Enable CyberPot service
sudo systemctl enable cyberpot.service
sudo systemctl daemon-reload

# Create monitoring script
log "Creating monitoring script..."
sudo tee /home/ubuntu/cyberpot/monitor-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot monitoring script

echo "=== CyberPot Status Check ==="
echo "Timestamp: $(date)"

# Check service status
echo "Service Status:"
sudo systemctl status cyberpot --no-pager -l

# Check Docker containers
echo "Docker Containers:"
sudo docker compose ps

# Check disk usage
echo "Disk Usage:"
df -h /home/ubuntu/cyberpot

# Check memory usage
echo "Memory Usage:"
free -h

# Check recent logs
echo "Recent Logs:"
sudo tail -n 10 /var/log/cyberpot/cyberpot.log 2>/dev/null || echo "No CyberPot logs found"

exit 0
EOF

sudo chmod +x /home/ubuntu/cyberpot/monitor-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/monitor-cyberpot.sh

log "CyberPot base dependencies installation completed successfully!"
log "Next: Run CyberPot installation script to complete setup"
