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

#Create the HMAC key for the associated service account 
resource "google_storage_hmac_key" "key" {
  service_account_email = "pos-service-account@open-targets-eu-dev.iam.gserviceaccount.com"
}

// Create a disk volume for Clickhouse data
resource "google_compute_disk" "clickhouse_data_disk" {
  project     = "open-targets-eu-dev"
  name        = local.clickhouse_disk_name
  description = "Clickhouse data disk"
  type        = "pd-ssd"
  # zone        = "europe-west1-b"
  size        = var.clickhouse_snapshot_source == null ? var.clickhouse_data_disk_size : null
  labels      = local.base_labels
  snapshot    = var.clickhouse_snapshot_source
}

// Create a disk volume for ElasticSearch data
resource "google_compute_disk" "open_search_data_disk" {
  project     = "open-targets-eu-dev"
  name        = local.open_search_disk_name
  description = "OpenSearch data disk"
  type        = "pd-ssd"
  # zone        = "europe-west1-b"
  size        = var.open_search_snapshot_source == null ? var.open_search_data_disk_size : null
  labels      = local.base_labels
  snapshot    = var.open_search_snapshot_source
}

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
  attached_disk {
    source      = google_compute_disk.clickhouse_data_disk.self_link
    device_name = local.clickhouse_disk_name
  }

  // Attach OpenSearch data disk
  attached_disk {
    source      = google_compute_disk.open_search_data_disk.self_link
    device_name = local.open_search_disk_name
  }

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
        POS_USER_NAME = local.posvm_remote_user_name
        BRANCH        = var.pos_git_branch
        DATABASE_NAMESPACE = var.database_namespace
        OPENSEARCH_DISK_NAME = google_compute_disk.open_search_data_disk.name
        OPENSEARCH_TARBALL   = var.open_search_tarball == true ? "true" : "false"
        CLICKHOUSE_DISK_NAME = google_compute_disk.clickhouse_data_disk.name
        CLICKHOUSE_TARBALL   = var.clickhouse_tarball == true ? "true" : "false"
        FORMAT_OS_DISK       = var.open_search_snapshot_source == null ? "true" : "false"
        FORMAT_CH_DISK       = var.clickhouse_snapshot_source == null ? "true" : "false"
        INSTANCE_LABEL       = random_string.posvm.result
      }
    )
    ssh-keys               = "${local.posvm_remote_user_name}:${tls_private_key.posvm.public_key_openssh}"
    google-logging-enabled = false
    pos_config = templatefile(
      "pos_config.tftpl",
      local.yaml_config_variables
    )
    s3_config = templatefile(
      "s3_config.tftpl",
      {
        GCS_BATH_PATH = var.clickhouse_backup_base_path
        ACCESS_KEY = google_storage_hmac_key.key.access_id
        SECRET_KEY = google_storage_hmac_key.key.secret
      }
    )

    google_storage_hmac_key_access_id = google_storage_hmac_key.key.access_id
    google_storage_hmac_key_secret    = google_storage_hmac_key.key.secret
  }
  service_account {
    email  = "pos-service-account@open-targets-eu-dev.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  labels = local.base_labels

  lifecycle {
    create_before_destroy = true
  }
  # connection {
  #   type        = "ssh"
  #   host        = self.network_interface[0].access_config[0].nat_ip
  #   user        = local.posvm_remote_user_name
  #   private_key = tls_private_key.posvm.private_key_pem
  # }
  # provisioner "file" {
  #   source      = "run.sh"
  #   destination = "/opt/platform-output-support/run_pos.sh"
  # }
  # // Adjust scripts permissions
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod 777 /opt/platform-output-support/run_pos.sh",
  #   ]
  # }
}