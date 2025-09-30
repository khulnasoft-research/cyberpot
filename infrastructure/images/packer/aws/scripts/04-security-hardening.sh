#!/bin/bash
# CyberPot Security Hardening Script for AWS AMI
# This script applies security hardening to the CyberPot instance

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

log "Starting CyberPot security hardening..."

# Configure SSH security
log "Configuring SSH security..."
sudo tee -a /etc/ssh/sshd_config << EOF

# CyberPot SSH Security Configuration
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ubuntu
EOF

# Restart SSH service
sudo systemctl restart ssh

# Configure automatic security updates
log "Configuring automatic security updates..."
sudo apt-get install -y unattended-upgrades
sudo tee /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure firewall for CyberPot-specific ports
log "Configuring firewall for CyberPot..."
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow CyberPot SSH (port 64295)
sudo ufw allow 64295/tcp

# Allow CyberPot Web UI (port 64297)
sudo ufw allow 64297/tcp

# Allow honeypot services (comprehensive range)
sudo ufw allow 1:64000/tcp
sudo ufw allow 1:64000/udp

# Allow established connections
sudo ufw allow out on all

# Allow loopback
sudo ufw allow in on lo
sudo ufw allow out on lo

# Enable firewall
sudo ufw --force enable

# Configure fail2ban for SSH protection
log "Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = auto
destemail = admin@localhost
sender = fail2ban@localhost

[sshd]
enabled = true
port = 64295
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[cyberpot-web]
enabled = true
port = 64297
filter = cyberpot-web
logpath = /var/log/cyberpot/access.log
maxretry = 10
bantime = 1800

[cyberpot-honeypot]
enabled = true
port = 1:64000
filter = cyberpot-honeypot
logpath = /var/log/cyberpot/honeypot.log
maxretry = 20
bantime = 900
EOF

# Create fail2ban filters for CyberPot
sudo tee /etc/fail2ban/filter.d/cyberpot-web.conf << EOF
[Definition]
failregex = ^<HOST> -.*"(GET|POST|PUT|DELETE).*" (404|403|401) .*$
            ^<HOST> -.*"(GET|POST|PUT|DELETE).*" 500 .*$
ignoreregex =
EOF

sudo tee /etc/fail2ban/filter.d/cyberpot-honeypot.conf << EOF
[Definition]
failregex = ^<HOST>.*(attack|exploit|malicious|brute.force).*
ignoreregex =
EOF

sudo systemctl restart fail2ban

# Configure audit daemon for security monitoring
log "Configuring audit daemon..."
sudo tee /etc/audit/rules.d/cyberpot.rules << EOF
# CyberPot Security Audit Rules

# Monitor file system modifications
-w /home/ubuntu/cyberpot/ -p wa -k cyberpot-modification
-w /etc/cyberpot/ -p wa -k cyberpot-config

# Monitor authentication events
-w /var/log/auth.log -p wa -k authentication
-w /var/log/sudo.log -p wa -k sudo-access

# Monitor network access
-a always,exit -F arch=b64 -S connect -S accept -S bind -k network-access

# Monitor privilege escalation
-a always,exit -F euid=0 -S execve -k privilege-escalation

# Monitor Docker events
-w /var/lib/docker/ -p wa -k docker-modification
-w /etc/docker/ -p wa -k docker-config

# Monitor cron jobs
-w /etc/crontab -p wa -k cron-modification
-w /etc/cron.d/ -p wa -k cron-modification
EOF

sudo systemctl restart auditd

# Install and configure rkhunter (Rootkit Hunter)
log "Installing and configuring rkhunter..."
sudo apt-get install -y rkhunter
sudo rkhunter --update
sudo rkhunter --propupd

# Configure daily rkhunter scan
sudo tee /etc/cron.daily/rkhunter-scan << 'EOF'
#!/bin/bash
# Daily rootkit scan

/usr/bin/rkhunter --check --cronjob --report-warnings-only | tee /var/log/rkhunter.log
EOF

sudo chmod +x /etc/cron.daily/rkhunter-scan

# Configure AIDE (Advanced Intrusion Detection Environment)
log "Configuring AIDE..."
sudo apt-get install -y aide aide-common
sudo aideinit

# Configure daily AIDE check
sudo tee /etc/cron.daily/aide-check << 'EOF'
#!/bin/bash
# Daily AIDE integrity check

/usr/bin/aide --check | tee /var/log/aide.log
EOF

sudo chmod +x /etc/cron.daily/aide-check

# Configure log security
log "Configuring log security..."
sudo tee -a /etc/rsyslog.conf << EOF

# CyberPot Log Security Configuration
\$FileOwner ubuntu
\$FileGroup ubuntu
\$FileCreateMode 0640
\$DirCreateMode 0750
\$Umask 0022

# CyberPot specific logs
local6.*                        /var/log/cyberpot/cyberpot.log
EOF

sudo systemctl restart rsyslog

# Create log directories with secure permissions
sudo mkdir -p /var/log/cyberpot
sudo chown ubuntu:ubuntu /var/log/cyberpot
sudo chmod 750 /var/log/cyberpot

# Configure sysctl for security
log "Configuring sysctl security parameters..."
sudo tee /etc/sysctl.d/99-cyberpot-security.conf << EOF
# CyberPot Security Kernel Parameters

# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1

# Protect against SYN flood attacks
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# Security logging
kernel.printk = 3 3 3 3
EOF

sudo sysctl -p /etc/sysctl.d/99-cyberpot-security.conf

# Create security monitoring script
log "Creating security monitoring script..."
sudo tee /home/ubuntu/cyberpot/security-monitor.sh << 'EOF'
#!/bin/bash
# CyberPot Security Monitoring Script

echo "=== CyberPot Security Status ==="
echo "Timestamp: $(date)"

# Check failed login attempts
echo "Recent Failed Logins:"
sudo grep "Failed password" /var/log/auth.log | tail -10 || echo "No failed logins found"

# Check firewall status
echo "Firewall Status:"
sudo ufw status

# Check fail2ban status
echo "Fail2ban Status:"
sudo fail2ban-client status sshd 2>/dev/null || echo "Fail2ban not configured for SSH"

# Check audit daemon
echo "Audit Daemon Status:"
sudo systemctl status auditd --no-pager -l | grep Active || echo "Audit daemon not running"

# Check rkhunter status
echo "Rootkit Hunter:"
sudo rkhunter --check --sk | tail -5

# Check for suspicious processes
echo "Suspicious Processes:"
ps aux | grep -vE "(root|ubuntu|systemd|docker)" | grep -E "(nc|netcat|wget|curl)" || echo "No suspicious processes found"

# Check open ports
echo "Open Ports:"
sudo ss -tuln | grep LISTEN | grep -vE "(127.0.0.1|::1)"

echo "Security monitoring completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/security-monitor.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/security-monitor.sh

# Create security update script
log "Creating security update script..."
sudo tee /home/ubuntu/cyberpot/security-update.sh << 'EOF'
#!/bin/bash
# CyberPot Security Update Script

echo "Applying security updates..."

# Update package lists
sudo apt-get update

# Install security updates only
sudo unattended-upgrade --dry-run
sudo unattended-upgrade

# Update virus definitions
sudo freshclam

# Update rkhunter database
sudo rkhunter --update

# Update AIDE database
sudo aide --update

# Restart services if needed
sudo systemctl reload-or-restart rsyslog
sudo systemctl reload-or-restart auditd

echo "Security updates completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/security-update.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/security-update.sh

log "CyberPot security hardening completed successfully!"
