#!/bin/bash
# CyberPot Installation Script for AWS AMI
# This script downloads and installs CyberPot during AMI creation

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

log "Starting CyberPot installation..."

# Get CyberPot version from environment or use default
CYBERPOT_VERSION="${CYBERPOT_VERSION:-24.04.1}"
log "Installing CyberPot version: $CYBERPOT_VERSION"

# Navigate to CyberPot directory
cd /home/ubuntu/cyberpot

# Clone CyberPot repository
log "Cloning CyberPot repository..."
git clone https://github.com/khulnasoft/cyberpot.git .
sudo chown -R ubuntu:ubuntu /home/ubuntu/cyberpot

# Create .env file with default configuration
log "Creating CyberPot configuration..."
cat > /home/ubuntu/cyberpot/.env << EOF
# CyberPot Configuration File
# Generated during AMI creation

# Web usernames and passwords (will be configured during deployment)
WEB_USER=admin:$(echo "changeme123" | htpasswd -bn -i admin | cut -d: -f2)

# Logstash Web usernames and passwords
LS_WEB_USER=logstash:$(echo "changeme123" | htpasswd -bn -i logstash | cut -d: -f2)

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
CYBERPOT_VERSION=$CYBERPOT_VERSION
CYBERPOT_PULL_POLICY=always
CYBERPOT_DATA_PATH=./data

# OSType
CYBERPOT_OSTYPE=linux

# Environment
CYBERPOT_ENVIRONMENT=production
EOF

# Set proper ownership
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/.env

# Create data directories
log "Creating data directories..."
mkdir -p /home/ubuntu/cyberpot/data
mkdir -p /home/ubuntu/cyberpot/backups
mkdir -p /home/ubuntu/cyberpot/logs
sudo chown -R ubuntu:ubuntu /home/ubuntu/cyberpot

# Create log files
touch /home/ubuntu/cyberpot/data/cyberpotinit.log
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/data/cyberpotinit.log

# Create Docker Compose override for production
log "Creating Docker Compose configuration..."
cat > /home/ubuntu/cyberpot/docker-compose.override.yml << EOF
version: '3.8'
services:
  cyberpot:
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  elasticsearch:
    restart: unless-stopped
    volumes:
      - ./data/elasticsearch:/usr/share/elasticsearch/data

  logstash:
    restart: unless-stopped

  kibana:
    restart: unless-stopped

  nginx:
    restart: unless-stopped
    ports:
      - "64297:80"
EOF

sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/docker-compose.override.yml

# Create health check script
log "Creating health check script..."
cat > /home/ubuntu/cyberpot/health-check.sh << 'EOF'
#!/bin/bash
# CyberPot Health Check Script

echo "=== CyberPot Health Check ==="
echo "Timestamp: $(date)"

# Check if containers are running
echo "Docker Containers Status:"
sudo docker compose ps

# Check disk space
echo "Disk Usage:"
df -h /home/ubuntu/cyberpot | tail -1

# Check memory usage
echo "Memory Usage:"
free -h

# Check recent logs for errors
echo "Recent Error Logs:"
sudo tail -n 20 /home/ubuntu/cyberpot/data/cyberpotinit.log | grep -i error || echo "No errors found"

# Check service status
echo "CyberPot Service Status:"
sudo systemctl status cyberpot --no-pager -l

echo "Health check completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/health-check.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/health-check.sh

# Create backup script
log "Creating backup script..."
cat > /home/ubuntu/cyberpot/backup-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Backup Script

BACKUP_DIR="/home/ubuntu/cyberpot/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="cyberpot_backup_${TIMESTAMP}.tar.gz"

echo "Creating CyberPot backup: $BACKUP_FILE"

# Stop CyberPot services
sudo systemctl stop cyberpot

# Create backup
cd /home/ubuntu/cyberpot
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude="data/elasticsearch/data" \
    --exclude="backups/*" \
    --exclude="*.log" \
    .

# Restart CyberPot services
sudo systemctl start cyberpot

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"
EOF

sudo chmod +x /home/ubuntu/cyberpot/backup-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/backup-cyberpot.sh

# Create update script
log "Creating update script..."
cat > /home/ubuntu/cyberpot/update-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Update Script

echo "Updating CyberPot..."

# Pull latest images
sudo docker compose pull

# Stop services
sudo docker compose down

# Update CyberPot files (if needed)
git pull

# Start services
sudo docker compose up -d

# Run health check
./health-check.sh

echo "Update completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/update-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/update-cyberpot.sh

# Test CyberPot installation
log "Testing CyberPot installation..."
cd /home/ubuntu/cyberpot

# Validate Docker Compose file
sudo docker compose config -q

# Check if required files exist
if [ ! -f docker-compose.yml ]; then
    log "ERROR: docker-compose.yml not found!"
    exit 1
fi

if [ ! -f .env ]; then
    log "ERROR: .env file not found!"
    exit 1
fi

log "CyberPot installation completed successfully!"
log "CyberPot is ready for deployment configuration."
