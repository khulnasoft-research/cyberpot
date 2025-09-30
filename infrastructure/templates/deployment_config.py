# CyberPot Deployment Configuration Templates
# Environment-specific configurations for different deployment scenarios

# =====================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =====================================================================
cyberpot_dev_config = {
    "environment": "dev",
    "instance_type": {"aws": "t3.medium", "azure": "Standard_B2s", "gcp": "e2-medium"},
    "data_volume_size": 128,
    "backup_retention_days": 7,
    "monitoring": {"enabled": True, "detailed": False, "alerts": ["cpu", "memory"]},
    "security": {
        "blackhole": "DISABLED",
        "persistence": "on",
        "firewall_strict": False,
    },
    "honeypots": {
        "enabled": ["cowrie", "heralding", "glutton"],
        "disabled": ["adbhoney", "ciscoasa", "conpot", "dionaea"],
    },
    "scaling": {"auto_scaling": False, "min_instances": 1, "max_instances": 1},
}

# =====================================================================
# STAGING ENVIRONMENT CONFIGURATION
# =====================================================================
cyberpot_staging_config = {
    "environment": "staging",
    "instance_type": {
        "aws": "t3.large",
        "azure": "Standard_B4ms",
        "gcp": "n2-standard-2",
    },
    "data_volume_size": 256,
    "backup_retention_days": 14,
    "monitoring": {
        "enabled": True,
        "detailed": True,
        "alerts": ["cpu", "memory", "disk", "network"],
    },
    "security": {"blackhole": "DISABLED", "persistence": "on", "firewall_strict": True},
    "honeypots": {
        "enabled": ["cowrie", "heralding", "glutton", "adbhoney", "ciscoasa"],
        "disabled": ["conpot", "dionaea", "elasticpot"],
    },
    "scaling": {"auto_scaling": False, "min_instances": 1, "max_instances": 2},
}

# =====================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =====================================================================
cyberpot_prod_config = {
    "environment": "prod",
    "instance_type": {
        "aws": "t3.xlarge",
        "azure": "Standard_D4s_v3",
        "gcp": "n2-standard-4",
    },
    "data_volume_size": 512,
    "backup_retention_days": 30,
    "monitoring": {
        "enabled": True,
        "detailed": True,
        "alerts": ["cpu", "memory", "disk", "network", "security"],
    },
    "security": {
        "blackhole": "ENABLED",
        "persistence": "on",
        "firewall_strict": True,
        "encryption": True,
        "ssl_verification": "full",
    },
    # Enable all available honeypots
    "honeypots": {"enabled": "all", "disabled": []},
    "scaling": {
        "auto_scaling": True,
        "min_instances": 2,
        "max_instances": 5,
        "cpu_threshold": 70,
    },
    "high_availability": {
        "enabled": True,
        "load_balancer": True,
        "health_checks": True,
    },
}

# =====================================================================
# SENSOR CONFIGURATION (for distributed deployment)
# =====================================================================
cyberpot_sensor_config = {
    "environment": "prod",
    "cyberpot_type": "SENSOR",
    "instance_type": {"aws": "t3.large", "azure": "Standard_B2s", "gcp": "e2-medium"},
    "data_volume_size": 128,
    "monitoring": {"enabled": True, "detailed": False, "alerts": ["cpu", "memory"]},
    "security": {
        "blackhole": "DISABLED",
        "persistence": "off",  # Sensors send logs to Hive
        "firewall_strict": True,
    },
    "honeypots": {
        "enabled": ["cowrie", "glutton", "heralding"],
        "disabled": ["adbhoney", "ciscoasa", "conpot"],
    },
    "distributed": {
        "hive_ip": "REQUIRED",  # Must be set to Hive IP
        "hive_user": "REQUIRED",  # Must be set to Hive credentials
        "ssl_verification": "full",
    },
}

# =====================================================================
# MINIMAL CONFIGURATION (for resource-constrained environments)
# =====================================================================
cyberpot_minimal_config = {
    "environment": "dev",
    "instance_type": {"aws": "t3.small", "azure": "Standard_B1s", "gcp": "e2-micro"},
    "data_volume_size": 64,
    "backup_retention_days": 3,
    "monitoring": {"enabled": False, "detailed": False, "alerts": []},
    "security": {
        "blackhole": "DISABLED",
        "persistence": "off",
        "firewall_strict": False,
    },
    "honeypots": {
        "enabled": ["glutton"],  # Only the most lightweight honeypot
        "disabled": "all",
    },
    "performance": {
        "low_resource_mode": True,
        "container_limits": True,
        "log_level": "warning",
    },
}

# =====================================================================
# HIGH-SECURITY CONFIGURATION
# =====================================================================
cyberpot_high_security_config = {
    "environment": "prod",
    "instance_type": {
        "aws": "c5.xlarge",
        "azure": "Standard_F8s_v2",
        "gcp": "n2-highmem-4",
    },
    "data_volume_size": 256,
    "backup_retention_days": 90,
    "monitoring": {
        "enabled": True,
        "detailed": True,
        "alerts": ["cpu", "memory", "disk", "network", "security", "audit"],
    },
    "security": {
        "blackhole": "ENABLED",
        "persistence": "on",
        "firewall_strict": True,
        "encryption": True,
        "ssl_verification": "full",
        "audit_logging": True,
        "intrusion_detection": True,
        "network_isolation": True,
    },
    "honeypots": {
        "enabled": ["cowrie", "glutton", "heralding", "endlessh"],
        # Disable high-interaction honeypots
        "disabled": ["adbhoney", "ciscoasa"],
    },
    "compliance": {
        "gdpr_compliant": True,
        "data_retention_policy": "90_days",
        "audit_trail": True,
        "access_logging": True,
    },
}

# =====================================================================
# DISTRIBUTED DEPLOYMENT CONFIGURATION
# =====================================================================
cyberpot_distributed_config = {
    "hive": {
        "environment": "prod",
        "instance_type": {
            "aws": "t3.xlarge",
            "azure": "Standard_D8s_v4",
            "gcp": "n2-standard-8",
        },
        "data_volume_size": 1024,
        "monitoring": {
            "enabled": True,
            "detailed": True,
            "alerts": ["cpu", "memory", "disk", "network"],
        },
        "security": {
            "blackhole": "ENABLED",
            "persistence": "on",
            "firewall_strict": True,
        },
        "elasticsearch": {"heap_size": "4g", "cluster_settings": "multi-node"},
    },
    "sensors": [
        {
            "name": "sensor-1",
            "location": "us-east-1",
            "honeypots": ["cowrie", "glutton", "heralding"],
        },
        {
            "name": "sensor-2",
            "location": "eu-west-1",
            "honeypots": ["adbhoney", "ciscoasa", "conpot"],
        },
    ],
}

# =====================================================================
# CUSTOM HONEYPOT CONFIGURATION
# =====================================================================
cyberpot_custom_honeypots = {
    "cowrie": {
        "enabled": True,
        "ports": [22, 23],
        "max_connections": 100,
        "log_level": "info",
    },
    "heralding": {
        "enabled": True,
        "ports": [21, 25, 110, 143, 993, 995],
        "capabilities": ["ftp", "smtp", "pop3", "imap"],
    },
    "glutton": {"enabled": True, "ports": "dynamic", "max_ports": 1000},
    "adbhoney": {"enabled": False, "ports": [5555], "download_artifacts": True},
    "ciscoasa": {"enabled": False, "ports": [5000, 8443], "protocol": "udp"},
}

# =====================================================================
# DEPLOYMENT SCRIPTS CONFIGURATION
# =====================================================================
deployment_scripts = {
    "pre_deploy": [
        "system_health_check.sh",
        "network_connectivity_test.sh",
        "disk_space_verification.sh",
    ],
    "post_deploy": [
        "service_verification.sh",
        "honeypot_connectivity_test.sh",
        "monitoring_setup.sh",
        "documentation_generation.sh",
    ],
    "maintenance": [
        "daily_backup.sh",
        "log_rotation.sh",
        "security_updates.sh",
        "performance_monitoring.sh",
    ],
}

# =====================================================================
# BACKUP AND DISASTER RECOVERY CONFIGURATION
# =====================================================================
backup_config = {
    "strategies": {
        "local": {"enabled": True, "retention_days": 7, "schedule": "daily"},
        "remote": {
            "enabled": True,
            "provider": "aws_s3",  # aws_s3, azure_blob, gcp_bucket
            "retention_days": 30,
            "schedule": "daily",
        },
        "offsite": {
            "enabled": False,
            "provider": "glacier",  # glacier, azure_archive, gcp_coldline
            "retention_days": 365,
            "schedule": "monthly",
        },
    },
    "components": {
        "configuration": True,
        "honeypot_data": True,
        "elasticsearch_indices": False,  # Too large for regular backup
        "system_configuration": True,
        "docker_images": False,  # Images can be pulled again
    },
}

# =====================================================================
# MONITORING AND ALERTING CONFIGURATION
# =====================================================================
monitoring_config = {
    "metrics": {
        "system": ["cpu", "memory", "disk", "network"],
        "docker": ["container_status", "resource_usage"],
        "cyberpot": ["honeypot_activity", "attack_patterns"],
        "security": ["failed_logins", "suspicious_activity"],
    },
    "alerts": {
        "high_cpu": {"threshold": 80, "duration": "5m", "channels": ["email", "slack"]},
        "high_memory": {
            "threshold": 85,
            "duration": "5m",
            "channels": ["email", "slack"],
        },
        "disk_full": {
            "threshold": 90,
            "duration": "1m",
            "channels": ["email", "slack", "sms"],
        },
        "service_down": {
            "threshold": 1,
            "duration": "2m",
            "channels": ["email", "slack", "pagerduty"],
        },
    },
    "dashboards": {
        "system_overview": True,
        "honeypot_activity": True,
        "attack_analysis": True,
        "performance_metrics": True,
    },
}
