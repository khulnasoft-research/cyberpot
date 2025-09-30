# CyberPot GCP Infrastructure as Code
# Main Terraform configuration for deploying CyberPot on Google Cloud Platform

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Provider configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Local variables
locals {
  name_prefix = "cyberpot-${var.environment}"
}

# VPC Network
resource "google_compute_network" "cyberpot" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.compute]

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Subnet
resource "google_compute_subnetwork" "cyberpot" {
  name          = "${local.name_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.cyberpot.id
  region        = var.gcp_region

  private_ip_google_access = true

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Firewall Rules
resource "google_compute_firewall" "ssh" {
  name    = "${local.name_prefix}-ssh"
  network = google_compute_network.cyberpot.name

  allow {
    protocol = "tcp"
    ports    = ["64295"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["cyberpot-instance"]

  depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "webui" {
  name    = "${local.name_prefix}-webui"
  network = google_compute_network.cyberpot.name

  allow {
    protocol = "tcp"
    ports    = ["64297"]
  }

  source_ranges = var.allowed_web_cidrs
  target_tags   = ["cyberpot-instance"]

  depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "honeypot_tcp" {
  name    = "${local.name_prefix}-honeypot-tcp"
  network = google_compute_network.cyberpot.name

  allow {
    protocol = "tcp"
    ports    = ["1-64000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cyberpot-instance"]

  depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "honeypot_udp" {
  name    = "${local.name_prefix}-honeypot-udp"
  network = google_compute_network.cyberpot.name

  allow {
    protocol = "udp"
    ports    = ["1-64000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cyberpot-instance"]

  depends_on = [google_project_service.compute]
}

resource "google_compute_firewall" "internal" {
  name    = "${local.name_prefix}-internal"
  network = google_compute_network.cyberpot.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["cyberpot-instance"]

  depends_on = [google_project_service.compute]
}

# Static IP Address
resource "google_compute_address" "cyberpot" {
  name   = "${local.name_prefix}-ip"
  region = var.gcp_region

  depends_on = [google_project_service.compute]

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Cloud Storage Bucket for backups
resource "google_storage_bucket" "cyberpot_backups" {
  name          = "${local.name_prefix}-backups-${random_id.bucket_suffix.hex}"
  location      = var.gcp_region
  force_destroy = var.environment != "production"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]

  tags = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Service Account for CyberPot instance
resource "google_service_account" "cyberpot" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "CyberPot Service Account"

  depends_on = [google_project_service.iam]
}

# IAM bindings for service account
resource "google_project_iam_binding" "log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.cyberpot.email}"
  ]

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_binding" "metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.cyberpot.email}"
  ]

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_binding" "storage_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.cyberpot.email}"
  ]

  depends_on = [google_project_service.iam]
}

# Compute Instance
resource "google_compute_instance" "cyberpot" {
  name         = "${local.name_prefix}-instance"
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.cyberpot_image != "" ? var.cyberpot_image : "ubuntu-2204-lts"
      size  = var.boot_disk_size
      type  = "pd-standard"

      labels = {
        Environment = var.environment
        Project     = "CyberPot"
      }
    }

    kms_key_self_link = var.kms_key_link
  }

  # Additional data disk
  dynamic "attached_disk" {
    for_each = var.data_disk_size > 0 ? [1] : []
    content {
      source      = google_compute_disk.cyberpot_data[0].self_link
      device_name = "cyberpot-data"
      mode        = "READ_WRITE"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.cyberpot.self_link
    network_ip = var.private_ip != "" ? var.private_ip : null

    access_config {
      nat_ip       = google_compute_address.cyberpot.address
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = google_service_account.cyberpot.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup-script.sh.tpl", {
    environment          = var.environment
    cyberpot_version     = var.cyberpot_version
    web_user_password    = random_password.web_user.result
    ls_web_user_password = random_password.ls_web_user.result
    domain_name          = var.domain_name != "" ? var.domain_name : google_compute_address.cyberpot.address
  })

  tags = ["cyberpot-instance"]

  labels = {
    Environment = var.environment
    Project     = "CyberPot"
    ManagedBy   = "Terraform"
  }

  depends_on = [google_project_service.compute]
}

# Additional data disk
resource "google_compute_disk" "cyberpot_data" {
  count = var.data_disk_size > 0 ? 1 : 0

  name = "${local.name_prefix}-data-disk"
  type = "pd-standard"
  zone = var.gcp_zone
  size = var.data_disk_size

  physical_block_size_bytes = 4096

  labels = {
    Environment = var.environment
    Project     = "CyberPot"
  }
}

# Cloud Monitoring Alert Policies
resource "google_monitoring_alert_policy" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  display_name = "${local.name_prefix}-High-CPU"
  combiner     = "OR"

  conditions {
    display_name = "CPU usage"

    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND resource.label.instance_id = \"${google_compute_instance.cyberpot.instance_id}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"

      threshold_value = 0.8
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  depends_on = [
    google_project_service.monitoring,
    google_compute_instance.cyberpot
  ]
}

resource "google_monitoring_alert_policy" "high_memory" {
  count = var.enable_monitoring ? 1 : 0

  display_name = "${local.name_prefix}-High-Memory"
  combiner     = "OR"

  conditions {
    display_name = "Memory usage"

    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND resource.label.instance_id = \"${google_compute_instance.cyberpot.instance_id}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"

      threshold_value = 0.9
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  depends_on = [
    google_project_service.monitoring,
    google_compute_instance.cyberpot
  ]
}

# Generate random passwords
resource "random_password" "web_user" {
  length  = 16
  special = true
}

resource "random_password" "ls_web_user" {
  length  = 16
  special = true
}

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable required GCP services
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "storage" {
  service = "storage.googleapis.com"
}

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}
