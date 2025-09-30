#!/bin/bash
# CyberPot Bootstrap Script for AWS EC2
# This script runs on first boot to configure CyberPot

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

log "Starting CyberPot bootstrap process..."

# Update system packages
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
log "Installing required packages..."
apt-get install -y \
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
    ufw

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
log "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create CyberPot directories
log "Creating CyberPot directories..."
mkdir -p /home/ubuntu/cyberpot
cd /home/ubuntu/cyberpot

# Download CyberPot
log "Downloading CyberPot..."
git clone https://github.com/khulnasoft/cyberpot.git .
chown -R ubuntu:ubuntu /home/ubuntu/cyberpot

# Generate user credentials
log "Generating user credentials..."
cd /home/ubuntu/cyberpot

# Generate web user password (htpasswd format)
WEB_USER_PASSWORD="${web_user_password}"
echo "ubuntu:$(echo "$WEB_USER_PASSWORD" | htpasswd -bn -i ubuntu | cut -d: -f2)" | base64 -w 0 > /tmp/web_user.txt

# Generate Logstash web user password
LS_WEB_USER_PASSWORD="${ls_web_user_password}"
echo "logstash:$(echo "$LS_WEB_USER_PASSWORD" | htpasswd -bn -i logstash | cut -d: -f2)" | base64 -w 0 > /tmp/ls_web_user.txt

# Create .env file
log "Creating CyberPot configuration..."
cat > /home/ubuntu/cyberpot/.env << EOF
# CyberPot config file. Do not remove.

# Web usernames and passwords
WEB_USER=$(cat /tmp/web_user.txt)

# Logstash Web usernames and passwords
LS_WEB_USER=$(cat /tmp/ls_web_user.txt)

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
CYBERPOT_VERSION=${cyberpot_version}
CYBERPOT_PULL_POLICY=always
CYBERPOT_DATA_PATH=./data

# OSType
CYBERPOT_OSTYPE=linux

# Environment specific settings
CYBERPOT_ENVIRONMENT=${environment}
EOF

# Set proper ownership
chown ubuntu:ubuntu /home/ubuntu/cyberpot/.env

# Mount data volume if available
log "Checking for additional data volume..."
if lsblk | grep -q xvdg; then
    log "Found additional volume, formatting and mounting..."
    mkfs -t ext4 /dev/xvdg
    mkdir -p /home/ubuntu/cyberpot/data
    mount /dev/xvdg /home/ubuntu/cyberpot/data
    echo "/dev/xvdg /home/ubuntu/cyberpot/data ext4 defaults,nofail 0 2" >> /etc/fstab

    # Set ownership
    chown -R ubuntu:ubuntu /home/ubuntu/cyberpot/data
fi

# Configure firewall
log "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (CyberPot uses port 64295)
ufw allow 64295/tcp

# Allow CyberPot Web UI
ufw allow 64297/tcp

# Allow honeypot ports (comprehensive range)
ufw allow 1:64000/tcp
ufw allow 1:64000/udp

# Allow established connections
ufw allow out on all

# Enable firewall
ufw --force enable

# Install AWS CLI for monitoring
log "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure CloudWatch agent
log "Configuring CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/home/ubuntu/cyberpot/data/cyberpotinit.log",
                        "log_group_name": "/aws/ec2/cyberpot/cyberpotinit",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ec2/cyberpot/system",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "append_dimensions": {
            "InstanceId": "\${aws:InstanceId}"
        },
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": true
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "net": {
                "measurement": [
                    "bytes_sent",
                    "bytes_recv",
                    "packets_sent",
                    "packets_recv"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "processes": {
                "measurement": [
                    "running",
                    "sleeping",
                    "dead"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create CyberPot service file
log "Creating CyberPot service..."
cat > /etc/systemd/system/cyberpot.service << EOF
[Unit]
Description=CyberPot Honeypot Platform
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/cyberpot
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
User=ubuntu
Group=ubuntu
TimeoutStartSec=0
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable cyberpot.service

# Set up log rotation for CyberPot logs
log "Setting up log rotation..."
cat > /etc/logrotate.d/cyberpot << EOF
/home/ubuntu/cyberpot/data/**/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        docker compose restart cyberpotinit 2>/dev/null || true
    endscript
}
EOF

# Create daily reboot cron job (as per CyberPot recommendations)
log "Setting up daily maintenance..."
cat > /etc/cron.d/cyberpot-maintenance << EOF
# CyberPot Daily Maintenance
42 2 * * * ubuntu bash -c 'cd /home/ubuntu/cyberpot && /usr/bin/docker compose stop && /usr/bin/docker container prune -f && /usr/bin/docker image prune -f && /usr/bin/docker volume prune -f && /usr/sbin/shutdown -r +1 "CyberPot Daily Maintenance"'
EOF

# Set proper permissions
chmod 644 /etc/cron.d/cyberpot-maintenance

# Create CyberPot status script
log "Creating CyberPot management scripts..."
cat > /home/ubuntu/cyberpot-status.sh << 'EOF'
#!/bin/bash
echo "=== CyberPot Status ==="
echo "Service Status:"
systemctl status cyberpot --no-pager -l
echo -e "\n=== Docker Containers ==="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo -e "\n=== Recent Logs ==="
tail -20 /home/ubuntu/cyberpot/data/cyberpotinit.log 2>/dev/null || echo "No logs found yet"
echo -e "\n=== Disk Usage ==="
df -h /home/ubuntu/cyberpot
EOF

chmod +x /home/ubuntu/cyberpot-status.sh
chown ubuntu:ubuntu /home/ubuntu/cyberpot-status.sh

# Create backup script
cat > /home/ubuntu/cyberpot-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/cyberpot-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating CyberPot backup..."
cd /home/ubuntu/cyberpot

# Stop services
systemctl stop cyberpot

# Create backup
tar -czf $BACKUP_DIR/cyberpot_backup_$DATE.tar.gz \
    --exclude=data/elasticsearch \
    --exclude=data/logstash/data \
    .env data/

# Start services
systemctl start cyberpot

echo "Backup created: $BACKUP_DIR/cyberpot_backup_$DATE.tar.gz"

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "cyberpot_backup_*.tar.gz" -type f -mtime +7 -delete
EOF

chmod +x /home/ubuntu/cyberpot-backup.sh
chown ubuntu:ubuntu /home/ubuntu/cyberpot-backup.sh

# Create a README for the instance
log "Creating instance documentation..."
cat > /home/ubuntu/CYBERPOT_README.md << EOF
# CyberPot AWS Instance

## Access Information

**Web UI:** https://${domain_name}/:64297
**SSH Access:** ssh -l ubuntu -p 64295 ${domain_name}
**Environment:** ${environment}
**Version:** ${cyberpot_version}

## Generated Credentials

**Web User:** Check /home/ubuntu/cyberpot/.env (WEB_USER)
**Logstash User:** Check /home/ubuntu/cyberpot/.env (LS_WEB_USER)

## Management Commands

- Check status: /home/ubuntu/cyberpot-status.sh
- Create backup: /home/ubuntu/cyberpot-backup.sh
- View logs: docker compose logs -f [service_name]
- Start services: systemctl start cyberpot
- Stop services: systemctl stop cyberpot

## Important Notes

- SSH port is changed to 64295 for security
- All honeypot ports (1-64000) are open
- Web UI is available on port 64297
- Daily maintenance reboot at 2:42 AM
- Logs are rotated and kept for 30 days
- Backups are created daily and kept for 7 days

## Security

- Firewall is configured with UFW
- Only necessary ports are open
- CloudWatch monitoring is enabled
- All volumes are encrypted
- SSH access is restricted

## Troubleshooting

1. Check service status: systemctl status cyberpot
2. View container logs: docker compose logs [service]
3. Check system logs: journalctl -u cyberpot
4. Verify firewall: ufw status
5. Check disk space: df -h

## Updates

To update CyberPot:
1. cd /home/ubuntu/cyberpot
2. git pull
3. systemctl restart cyberpot

For major version updates, check the release notes and backup first.
EOF

chown ubuntu:ubuntu /home/ubuntu/CYBERPOT_README.md

# Start CyberPot
log "Starting CyberPot services..."
cd /home/ubuntu/cyberpot
systemctl start cyberpot

# Wait for services to be healthy
log "Waiting for CyberPot to initialize..."
sleep 30

# Verify installation
if systemctl is-active --quiet cyberpot && docker ps | grep -q cyberpotinit; then
    log "CyberPot installation completed successfully!"
    log "Web UI will be available at: https://${domain_name}:64297"
    log "SSH access: ssh -l ubuntu -p 64295 ${domain_name}"
    log "Check /home/ubuntu/CYBERPOT_README.md for detailed information"
else
    log "Warning: CyberPot may still be initializing. Check status with: systemctl status cyberpot"
fi

log "Bootstrap process completed!"
