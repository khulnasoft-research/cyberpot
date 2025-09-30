#!/bin/bash
# CyberPot Monitoring Setup Script for AWS AMI
# This script configures monitoring and alerting for CyberPot

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

log "Setting up CyberPot monitoring..."

# Configure CloudWatch agent
log "Configuring CloudWatch agent..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
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
                    },
                    {
                        "file_path": "/var/log/auth.log",
                        "log_group_name": "/aws/ec2/cyberpot/auth",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60,
                "resources": ["*"],
                "totalcpu": true
            },
            "disk": {
                "measurement": ["used_percent", "inodes_free"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "memory": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "processes": {
                "measurement": ["running", "total"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

# Create custom metrics script for CyberPot
log "Creating CyberPot metrics collection script..."
sudo tee /home/ubuntu/cyberpot/collect-metrics.sh << 'EOF'
#!/bin/bash
# CyberPot Custom Metrics Collection

# Get CyberPot container status
CYBERPOT_CONTAINERS=$(sudo docker compose ps -q | wc -l)
CYBERPOT_RUNNING=$(sudo docker compose ps | grep -c "Up")

# Get honeypot activity (if log file exists)
HONEYPOT_ATTACKS=0
if [ -f /home/ubuntu/cyberpot/data/cyberpotinit.log ]; then
    HONEYPOT_ATTACKS=$(grep -c "attack\|connection\|login" /home/ubuntu/cyberpot/data/cyberpotinit.log 2>/dev/null || echo 0)
fi

# Get disk usage for CyberPot data
CYBERPOT_DATA_USAGE=$(df /home/ubuntu/cyberpot | tail -1 | awk '{print $5}' | sed 's/%//')

# Output metrics in CloudWatch format
echo "CyberPotContainers,InstanceId=$(ec2-metadata -i | cut -d' ' -f2) Containers=$CYBERPOT_CONTAINERS"
echo "CyberPotRunning,InstanceId=$(ec2-metadata -i | cut -d' ' -f2) Running=$CYBERPOT_RUNNING"
echo "CyberPotAttacks,InstanceId=$(ec2-metadata -i | cut -d' ' -f2) Attacks=$HONEYPOT_ATTACKS"
echo "CyberPotDataUsage,InstanceId=$(ec2-metadata -i | cut -d' ' -f2) Usage=$CYBERPOT_DATA_USAGE"
EOF

sudo chmod +x /home/ubuntu/cyberpot/collect-metrics.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/collect-metrics.sh

# Set up cron job for metrics collection (every 5 minutes)
sudo tee /etc/cron.d/cyberpot-metrics << EOF
*/5 * * * * ubuntu /home/ubuntu/cyberpot/collect-metrics.sh | awk -F',' '{print \$1,\$2}' | while read metric value; do aws cloudwatch put-metric-data --metric-name "\$metric" --namespace "CyberPot" --value "\$value" --unit Count --region $(ec2-metadata -v | cut -d' ' -f2); done
EOF

# Create CloudWatch dashboard configuration
log "Creating CloudWatch dashboard configuration..."
sudo tee /home/ubuntu/cyberpot/cyberpot-dashboard.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["CyberPot", "CyberPotContainers"],
                    [".", "CyberPotRunning"],
                    [".", "CyberPotAttacks"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$(ec2-metadata -v | cut -d' ' -f2)",
                "title": "CyberPot Overview",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/EC2", "CPUUtilization"],
                    [".", "DiskSpaceUtilization"],
                    [".", "MemoryUtilization"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$(ec2-metadata -v | cut -d' ' -f2)",
                "title": "System Resources"
            }
        }
    ]
}
EOF

sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/cyberpot-dashboard.json

# Create alerting configuration
log "Creating CloudWatch alarm configuration..."
sudo tee /home/ubuntu/cyberpot/cyberpot-alarms.json << EOF
{
    "Alarms": [
        {
            "AlarmName": "CyberPot High CPU Usage",
            "AlarmDescription": "CPU usage is above 80% for 5 minutes",
            "MetricName": "CPUUtilization",
            "Namespace": "AWS/EC2",
            "Statistic": "Average",
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 80.0,
            "ComparisonOperator": "GreaterThanThreshold",
            "ActionsEnabled": false
        },
        {
            "AlarmName": "CyberPot High Memory Usage",
            "AlarmDescription": "Memory usage is above 85% for 5 minutes",
            "MetricName": "MemoryUtilization",
            "Namespace": "AWS/EC2",
            "Statistic": "Average",
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 85.0,
            "ComparisonOperator": "GreaterThanThreshold",
            "ActionsEnabled": false
        },
        {
            "AlarmName": "CyberPot Service Down",
            "AlarmDescription": "CyberPot containers are not running",
            "MetricName": "CyberPotRunning",
            "Namespace": "CyberPot",
            "Statistic": "Average",
            "Period": 300,
            "EvaluationPeriods": 2,
            "Threshold": 1.0,
            "ComparisonOperator": "LessThanThreshold",
            "ActionsEnabled": false
        }
    ]
}
EOF

sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/cyberpot-alarms.json

# Create monitoring status script
log "Creating monitoring status script..."
sudo tee /home/ubuntu/cyberpot/monitoring-status.sh << 'EOF'
#!/bin/bash
# CyberPot Monitoring Status Script

echo "=== CyberPot Monitoring Status ==="
echo "Timestamp: $(date)"

# Check CloudWatch agent status
echo "CloudWatch Agent:"
sudo systemctl status amazon-cloudwatch-agent --no-pager -l

# Check cron jobs
echo "Cron Jobs:"
sudo crontab -l | grep -E "(cyberpot|metrics)" || echo "No CyberPot cron jobs found"

# Check metrics collection
echo "Recent Metrics:"
sudo docker compose ps | grep -E "(Up|Exit)" | wc -l

# Check alarm status
echo "CloudWatch Alarms:"
aws cloudwatch describe-alarms --alarm-names "CyberPot%" --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table 2>/dev/null || echo "No CyberPot alarms configured"

echo "Monitoring status check completed."
EOF

sudo chmod +x /home/ubuntu/cyberpot/monitoring-status.sh
sudo chown ubuntu:ubuntu /home/ubuntu/cyberpot/monitoring-status.sh

log "CyberPot monitoring setup completed successfully!"
