#cloud-config
# CyberPot Cloud-Init configuration for Azure

package_update: true
package_upgrade: true

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - git
  - htop
  - vim
  - wget
  - jq
  - python3-pip
  - ufw
  - software-properties-common

groups:
  - docker

users:
  - name: ${admin_username}
    groups: [docker, sudo]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_public_key}

# Install Docker
runcmd:
  # Install Docker
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Start and enable Docker
  - systemctl start docker
  - systemctl enable docker

  # Create CyberPot directories
  - mkdir -p /home/${admin_username}/cyberpot
  - cd /home/${admin_username}/cyberpot

  # Clone CyberPot repository
  - git clone https://github.com/khulnasoft/cyberpot.git .
  - chown -R ${admin_username}:${admin_username} /home/${admin_username}/cyberpot

  # Generate user credentials and create .env file
  - cd /home/${admin_username}/cyberpot

  # Generate web user password (htpasswd format)
  - WEB_USER_PASSWORD="${web_user_password}"
  - echo "${admin_username}:$(echo "$WEB_USER_PASSWORD" | htpasswd -bn -i ${admin_username} | cut -d: -f2)" | base64 -w 0 > /tmp/web_user.txt

  # Generate Logstash web user password
  - LS_WEB_USER_PASSWORD="${ls_web_user_password}"
  - echo "logstash:$(echo "$LS_WEB_USER_PASSWORD" | htpasswd -bn -i logstash | cut -d: -f2)" | base64 -w 0 > /tmp/ls_web_user.txt

  # Create .env file
  - cat > /home/${admin_username}/cyberpot/.env << EOF
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
  - chown ${admin_username}:${admin_username} /home/${admin_username}/cyberpot/.env

  # Format and mount data disk if available
  - |
    # Check for additional data disk
    if [ -b /dev/sdc ]; then
      echo "Found data disk, formatting and mounting..."
      parted /dev/sdc --script mklabel gpt mkpart primary ext4 0% 100%
      mkfs.ext4 /dev/sdc1
      mkdir -p /home/${admin_username}/cyberpot/data
      mount /dev/sdc1 /home/${admin_username}/cyberpot/data
      echo "/dev/sdc1 /home/${admin_username}/cyberpot/data ext4 defaults,nofail 0 2" >> /etc/fstab
      chown -R ${admin_username}:${admin_username} /home/${admin_username}/cyberpot/data
    fi

  # Configure firewall
  - ufw --force reset
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow 64295/tcp  # SSH (CyberPot port)
  - ufw allow 64297/tcp  # Web UI
  - ufw allow 1:64000/tcp # Honeypot TCP services
  - ufw allow 1:64000/udp # Honeypot UDP services
  - ufw allow out on all  # Allow outbound connections
  - ufw --force enable

  # Install Azure CLI and monitoring agent
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  - wget https://aka.ms/azmonagent -O /tmp/azure-monitor-agent.deb
  - dpkg -i /tmp/azure-monitor-agent.deb || apt-get install -f -y

  # Create CyberPot service file
  - cat > /etc/systemd/system/cyberpot.service << EOF
[Unit]
Description=CyberPot Honeypot Platform
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/${admin_username}/cyberpot
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
User=${admin_username}
Group=${admin_username}
TimeoutStartSec=0
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd and enable service
  - systemctl daemon-reload
  - systemctl enable cyberpot.service

  # Set up log rotation
  - cat > /etc/logrotate.d/cyberpot << EOF
/home/${admin_username}/cyberpot/data/**/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 ${admin_username} ${admin_username}
    postrotate
        docker compose restart cyberpotinit 2>/dev/null || true
    endscript
}
EOF

  # Create daily maintenance cron job
  - cat > /etc/cron.d/cyberpot-maintenance << EOF
# CyberPot Daily Maintenance
42 2 * * * ${admin_username} bash -c 'cd /home/${admin_username}/cyberpot && /usr/bin/docker compose stop && /usr/bin/docker container prune -f && /usr/bin/docker image prune -f && /usr/bin/docker volume prune -f && /usr/sbin/shutdown -r +1 "CyberPot Daily Maintenance"'
EOF

  # Set proper permissions
  - chmod 644 /etc/cron.d/cyberpot-maintenance

  # Create management scripts
  - cat > /home/${admin_username}/cyberpot-status.sh << 'EOF'
#!/bin/bash
echo "=== CyberPot Status ==="
echo "Service Status:"
systemctl status cyberpot --no-pager -l
echo -e "\n=== Docker Containers ==="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo -e "\n=== Recent Logs ==="
tail -20 /home/${admin_username}/cyberpot/data/cyberpotinit.log 2>/dev/null || echo "No logs found yet"
echo -e "\n=== Disk Usage ==="
df -h /home/${admin_username}/cyberpot
EOF

  - chmod +x /home/${admin_username}/cyberpot-status.sh
  - chown ${admin_username}:${admin_username} /home/${admin_username}/cyberpot-status.sh

  # Create backup script
  - cat > /home/${admin_username}/cyberpot-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/${admin_username}/cyberpot-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating CyberPot backup..."
cd /home/${admin_username}/cyberpot

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

  - chmod +x /home/${admin_username}/cyberpot-backup.sh
  - chown ${admin_username}:${admin_username} /home/${admin_username}/cyberpot-backup.sh

  # Create README file
  - cat > /home/${admin_username}/CYBERPOT_README.md << EOF
# CyberPot Azure VM

## Access Information

**Web UI:** https://${domain_name}:64297
**SSH Access:** ssh -l ${admin_username} -p 64295 ${domain_name}
**Environment:** ${environment}
**Version:** ${cyberpot_version}

## Generated Credentials

**Web User:** Check /home/${admin_username}/cyberpot/.env (WEB_USER)
**Logstash User:** Check /home/${admin_username}/cyberpot/.env (LS_WEB_USER)

## Management Commands

- Check status: /home/${admin_username}/cyberpot-status.sh
- Create backup: /home/${admin_username}/cyberpot-backup.sh
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
- Azure Monitor is enabled for monitoring
- All disks are encrypted
- SSH access is restricted

## Troubleshooting

1. Check service status: systemctl status cyberpot
2. View container logs: docker compose logs [service]
3. Check system logs: journalctl -u cyberpot
4. Verify firewall: ufw status
5. Check disk space: df -h

## Updates

To update CyberPot:
1. cd /home/${admin_username}/cyberpot
2. git pull
3. systemctl restart cyberpot

For major version updates, check the release notes and backup first.
EOF

  - chown ${admin_username}:${admin_username} /home/${admin_username}/CYBERPOT_README.md

  # Start CyberPot
  - cd /home/${admin_username}/cyberpot
  - systemctl start cyberpot

  # Final setup message
  - echo "CyberPot installation completed!" > /tmp/cyberpot-setup.log
  - echo "Web UI: https://${domain_name}:64297" >> /tmp/cyberpot-setup.log
  - echo "SSH: ssh -l ${admin_username} -p 64295 ${domain_name}" >> /tmp/cyberpot-setup.log

# Final message
final_message: "CyberPot has been successfully deployed on Azure! Check /tmp/cyberpot-setup.log for access information."

# Power state change
power_state:
  mode: reboot
  message: "Rebooting after CyberPot installation"
  timeout: 30
