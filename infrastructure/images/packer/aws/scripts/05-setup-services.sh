#!/bin/bash
# CyberPot Services Setup Script for AWS AMI
# This script configures CyberPot services and creates systemd service files

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

log "Setting up CyberPot services..."

# Create systemd service for CyberPot
log "Creating CyberPot systemd service..."
sudo tee /etc/systemd/system/cyberpot.service << EOF
[Unit]
Description=CyberPot Honeypot Platform
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/cyberpot
ExecStart=/bin/bash /home/ubuntu/cyberpot/start-cyberpot.sh
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
TimeoutStartSec=300
TimeoutStopSec=60
TimeoutSec=300
User=ubuntu
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=DOCKER_HOST=unix:///var/run/docker.sock

# Restart policy
Restart=on-failure
RestartSec=30

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/ubuntu/cyberpot /var/log/cyberpot
PrivateDevices=false

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable CyberPot service
sudo systemctl enable cyberpot.service

# Create CyberPot startup script
log "Creating CyberPot startup script..."
sudo tee /home/ubuntu/cyberpot/start-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Startup Script

set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting CyberPot services..."

cd /home/ubuntu/cyberpot

# Check if .env file exists and is configured
if [ ! -f .env ]; then
    log "ERROR: CyberPot configuration (.env) not found!"
    exit 1
fi

# Validate Docker Compose configuration
if ! docker compose config -q; then
    log "ERROR: Invalid Docker Compose configuration"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p /var/log/cyberpot

# Pull latest CyberPot images
log "Pulling CyberPot Docker images..."
docker compose pull

# Start CyberPot services
log "Starting CyberPot services..."
docker compose up -d

# Wait for services to be ready
sleep 30

# Verify services are running
if docker compose ps | grep -q "Up"; then
    log "CyberPot services started successfully"

    # Log successful startup
    echo "$(date): CyberPot services started successfully" >> /var/log/cyberpot/cyberpot.log

    # Create status file
    echo "$(date)" > /home/ubuntu/cyberpot/.last_startup

    exit 0
else
    log "ERROR: Failed to start CyberPot services"

    # Log failure
    echo "$(date): Failed to start CyberPot services" >> /var/log/cyberpot/cyberpot.log

    exit 1
fi
EOF

sudo chmod +x /home/ubuntu/cyberpot/start-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/start-cyberpot.sh

# Create CyberPot stop script
log "Creating CyberPot stop script..."
sudo tee /home/ubuntu/cyberpot/stop-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Stop Script

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Stopping CyberPot services..."

cd /home/ubuntu/cyberpot

# Stop CyberPot services gracefully
docker compose down

# Clean up any orphaned containers
docker compose rm -f 2>/dev/null || true

# Log successful shutdown
echo "$(date): CyberPot services stopped" >> /var/log/cyberpot/cyberpot.log

log "CyberPot services stopped successfully"
EOF

sudo chmod +x /home/ubuntu/cyberpot/stop-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/stop-cyberpot.sh

# Create CyberPot status script
log "Creating CyberPot status script..."
sudo tee /home/ubuntu/cyberpot/status-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Status Script

echo "=== CyberPot Status Report ==="
echo "Timestamp: $(date)"
echo

# Service status
echo "Systemd Service:"
sudo systemctl status cyberpot --no-pager -l
echo

# Docker containers
echo "Docker Containers:"
sudo docker compose ps
echo

# Resource usage
echo "Resource Usage:"
echo "Disk Usage:"
df -h /home/ubuntu/cyberpot
echo
echo "Memory Usage:"
free -h
echo

# Recent logs
echo "Recent Logs:"
sudo tail -n 10 /var/log/cyberpot/cyberpot.log 2>/dev/null || echo "No CyberPot logs found"
echo

# Network connections (CyberPot-related)
echo "Network Connections:"
sudo ss -tuln | grep -E "(64295|64297)" || echo "No CyberPot ports found"
echo

echo "Status check completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/status-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/status-cyberpot.sh

# Create log rotation for CyberPot logs
log "Creating log rotation configuration..."
sudo tee /etc/logrotate.d/cyberpot << EOF
# CyberPot Log Rotation

/var/log/cyberpot/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        sudo systemctl reload rsyslog 2>/dev/null || true
        sudo docker compose restart 2>/dev/null || true
    endscript
}

/home/ubuntu/cyberpot/data/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOF

# Create maintenance script
log "Creating maintenance script..."
sudo tee /home/ubuntu/cyberpot/maintenance.sh << 'EOF'
#!/bin/bash
# CyberPot Maintenance Script

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Running CyberPot maintenance..."

# Clean up old Docker images
log "Cleaning Docker images..."
docker image prune -f

# Clean up old containers
log "Cleaning Docker containers..."
docker container prune -f

# Clean up old volumes (excluding CyberPot data)
log "Cleaning Docker volumes..."
docker volume prune -f

# Update virus definitions
log "Updating virus definitions..."
freshclam

# Run security scan
log "Running security scan..."
rkhunter --check --sk

# Check for CyberPot updates
log "Checking for CyberPot updates..."
cd /home/ubuntu/cyberpot
git fetch origin
if git status | grep -q "behind"; then
    log "CyberPot updates available. Run update script to apply."
else
    log "CyberPot is up to date."
fi

# Clean temporary files
log "Cleaning temporary files..."
find /tmp -type f -mtime +7 -delete
find /var/tmp -type f -mtime +7 -delete

log "Maintenance completed successfully"
EOF

sudo chmod +x /home/ubuntu/cyberpot/maintenance.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/maintenance.sh

# Set up cron jobs for maintenance
log "Setting up maintenance cron jobs..."
sudo tee /etc/cron.d/cyberpot-maintenance << EOF
# CyberPot Maintenance Jobs

# Daily maintenance at 2 AM
0 2 * * * ubuntu /home/ubuntu/cyberpot/maintenance.sh

# Hourly health check
0 * * * * ubuntu /home/ubuntu/cyberpot/health-check.sh

# Security monitoring every 6 hours
0 */6 * * * ubuntu /home/ubuntu/cyberpot/security-monitor.sh
EOF

# Create service management script
log "Creating service management script..."
sudo tee /home/ubuntu/cyberpot/manage-cyberpot.sh << 'EOF'
#!/bin/bash
# CyberPot Service Management Script

case "${1:-status}" in
    start)
        echo "Starting CyberPot..."
        sudo systemctl start cyberpot
        ;;
    stop)
        echo "Stopping CyberPot..."
        sudo systemctl stop cyberpot
        ;;
    restart)
        echo "Restarting CyberPot..."
        sudo systemctl restart cyberpot
        ;;
    status)
        echo "CyberPot Status:"
        sudo systemctl status cyberpot --no-pager -l
        echo
        echo "Docker Containers:"
        sudo docker compose ps
        ;;
    logs)
        echo "CyberPot Logs:"
        sudo journalctl -u cyberpot -n 50 --no-pager
        ;;
    update)
        echo "Updating CyberPot..."
        cd /home/ubuntu/cyberpot
        sudo docker compose pull
        sudo docker compose down
        sudo docker compose up -d
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

sudo chmod +x /home/ubuntu/cyberpot/manage-cyberpot.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/manage-cyberpot.sh

log "CyberPot services setup completed successfully!"
log "CyberPot is now ready for deployment and operation."
