terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.28.0"
    }
  }
  backend "gcs" {
    bucket = "open-targets-ops"
    prefix = "terraform/platform-pos-v2"
  }
}

provider "google" {
  region  = "europe-west1"
  project = "open-targets-eu-dev"
  zone    = "europe-west1-d"
}

resource "random_string" "posvm" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

resource "tls_private_key" "posvm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create a disk volume for Clickhouse data
# resource "google_compute_disk" "clickhouse_data_disk" {
#   project     = "open-targets-eu-dev"
#   name        = local.clickhouse_disk_name
#   description = "Clickhouse data disk"
#   type        = "pd-ssd"
#   zone        = "europe-west1-d"
#   size        = var.clickhouse_snapshot == null ? var.clickhouse_data_disk_size : null
#   labels      = local.base_labels
#   snapshot    = var.clickhouse_snapshot
# }

# // Create a disk volume for ElasticSearch data
# resource "google_compute_disk" "open_search_data_disk" {
#   project     = "open-targets-eu-dev"
#   name        = local.open_search_disk_name
#   description = "OpenSearch data disk"
#   type        = "pd-ssd"
#   zone        = "europe-west1-d"
#   size        = var.open_search_snapshot == null ? var.open_search_data_disk_size : null
#   labels      = local.base_labels
#   snapshot    = var.open_search_snapshot
# }

// Create a VM instance for the POS service
resource "google_compute_instance" "posvm" {
  name         = "posvm-${random_string.posvm.result}"
  machine_type = var.vm_pos_machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      type  = "pd-ssd"
      size  = var.vm_pos_boot_disk_size
    }
  }

  // Attach Clickhouse data disk
  # attached_disk {
  #   source      = google_compute_disk.clickhouse_data_disk.self_link
  #   device_name = local.clickhouse_disk_name
  # }

  # // Attach OpenSearch data disk
  # attached_disk {
  #   source      = google_compute_disk.open_search_data_disk.self_link
  #   device_name = local.open_search_disk_name
  # }

  network_interface {
    network = "default"
    access_config {
      // ephemeral public ip
    }
  }

  metadata = {
    startup-script = templatefile(
      "startup.sh",
      {
        POS_USER_NAME        = local.posvm_remote_user_name
        OPENSEARCH_DISK_NAME = "foo"
        CLICKHOUSE_DISK_NAME = "bar"
        BRANCH               = var.pos_git_branch
        # OPENSEARCH_DISK_NAME = google_compute_disk.open_search_data_disk.name
        # CLICKHOUSE_DISK_NAME = google_compute_disk.clickhouse_data_disk.name
        FORMAT_DISK          = var.open_search_snapshot == null ? "true" : "false"
      }
    )
    ssh-keys               = "${local.posvm_remote_user_name}:${tls_private_key.posvm.public_key_openssh}"
    google-logging-enabled = true
  }
  service_account {
    email  = "pos-service-account@open-targets-eu-dev.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  labels = local.base_labels

  lifecycle {
    create_before_destroy = true
  }


}