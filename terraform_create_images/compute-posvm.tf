// This file defines the VM used for post-production, i.e. for creating the data disk images, a.k.a. POS VM.

// This random with keepers is here just for development purposes, as running POS should be a disposable process.
resource "random_string" "posvm" {
  length  = 8
  lower   = true
  upper   = false
  special = false
  keepers = {
    vm_pos_boot_disk_size = var.config_vm_pos_boot_disk_size
    // Take into account the machine type as well
    machine_type = var.config_vm_pos_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/posvm/startup.sh"))
  }
}

// Key pair for SSH access
resource "tls_private_key" "posvm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create a disk volume for Clickhouse data
resource "google_compute_disk" "clickhouse_data_disk" {
  project     = var.config_project_id
  name        = local.disk_image_name_clickhouse
  description = "Clickhouse data disk"
  type        = "pd-ssd"
  zone        = var.config_gcp_default_zone
  size        = var.config_clickhouse_data_disk_size
  labels      = local.base_labels
}

// Create a disk volume for ElasticSearch data
resource "google_compute_disk" "elastic_search_data_disk" {
  project     = var.config_project_id
  name        = local.disk_image_name_elastic_search
  description = "ElasticSearch data disk"
  type        = "pd-ssd"
  zone        = var.config_gcp_default_zone
  size        = var.config_elastic_search_data_disk_size
  labels      = local.base_labels
}



// POS VM instance definition
resource "google_compute_instance" "posvm" {
  project                   = var.config_project_id
  name                      = "${local.posvm_name_prefix}-${random_string.posvm.result}"
  machine_type              = var.config_vm_pos_machine_type
  zone                      = var.config_gcp_default_zone
  allow_stopping_for_update = true
  // TODO This should be set to false
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = var.config_vm_pos_boot_image
      type  = "pd-ssd"
      size  = var.config_vm_pos_boot_disk_size
    }
  }

  // Attach Clickhouse data disk
  attached_disk {
    source      = google_compute_disk.clickhouse_data_disk.self_link
    device_name = local.data_disk_device_name_clickhouse
  }

  // Attach ElasticSearch data disk
  attached_disk {
    source      = google_compute_disk.elastic_search_data_disk.self_link
    device_name = local.data_disk_device_name_elastic_search
  }

  // WARNING - Does this machine need a public IP. No cloud routing for eu-dev.
  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = templatefile(
      "${path.module}/scripts/posvm/startup.sh",
      {
        PROJECT_ID                                  = var.config_project_id,
        GC_ZONE                                     = var.config_gcp_default_zone,
        GS_ETL_DATASET                              = var.config_gs_etl,
        IS_PARTNER_INSTANCE                         = var.is_partner_instance,
        GS_DIRECT_FILES                             = var.config_direct_json,
        GCP_DEVICE_DISK_PREFIX                      = local.gcp_device_disk_prefix,
        DATA_DISK_DEVICE_NAME_CH                    = local.data_disk_device_name_clickhouse,
        DATA_DISK_DEVICE_NAME_ES                    = local.data_disk_device_name_elastic_search,
        DISK_IMAGE_NAME_CH                          = local.disk_image_name_clickhouse,
        DISK_IMAGE_NAME_ES                          = local.disk_image_name_elastic_search,
        POS_REPO_BRANCH                             = var.config_repo_branch_pos,
        FLAG_POSTPROCESSING_SCRIPTS_READY           = local.flag_postprocessing_scripts_ready,
        PATH_POSTPROCESSING_SCRIPTS                 = local.path_postprocessing_scripts,
        FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT = local.filename_postprocessing_scripts_entry_point,
        # TODO Removev this
        CLICKHOUSE_URI    = "http://localhost:8123",
        ELASTICSEARCH_URI = "http://localhost:9200",
        IMAGE_PREFIX      = "IMGPREFIX_REMOVE_ME",
      }
    )
    ssh-keys               = "${local.posvm_remote_user_name}:${tls_private_key.posvm.public_key_openssh}"
    google-logging-enabled = true
  }

  service_account {
    email  = "pos-service-account@${var.config_project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  // We add the lifecyle configuration
  lifecycle {
    create_before_destroy = true
  }

  // Provision the postproduction scripts
  connection {
    type        = "ssh"
    host        = self.network_interface[0].access_config[0].nat_ip
    user        = local.posvm_remote_user_name
    private_key = tls_private_key.posvm.private_key_pem
  }
  // Create remote folders
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.path_postprocessing_scripts}",
    ]
  }
  // Commong configuration
  provisioner "file" {
    content = templatefile("${path.module}/scripts/config.sh", {
      PROJECT_ID                                  = var.config_project_id,
      GC_ZONE                                     = var.config_gcp_default_zone,
      GS_ETL_DATASET                              = var.config_gs_etl,
      IS_PARTNER_INSTANCE                         = var.is_partner_instance,
      GS_DIRECT_FILES                             = var.config_direct_json,
      GCP_DEVICE_DISK_PREFIX                      = local.gcp_device_disk_prefix,
      DATA_DISK_DEVICE_NAME_CH                    = local.data_disk_device_name_clickhouse,
      DATA_DISK_DEVICE_NAME_ES                    = local.data_disk_device_name_elastic_search,
      DISK_IMAGE_NAME_CH                          = local.disk_image_name_clickhouse,
      DISK_IMAGE_NAME_ES                          = local.disk_image_name_elastic_search,
      PATH_MOUNT_DATA_CLICKHOUSE                  = local.path_mount_data_clickhouse,
      PATH_MOUNT_DATA_ELASTICSEARCH               = local.path_mount_data_elastic_search,
      POS_REPO_BRANCH                             = var.config_repo_branch_pos,
      FLAG_POSTPROCESSING_SCRIPTS_READY           = local.flag_postprocessing_scripts_ready,
      PATH_POSTPROCESSING_ROOT                    = local.path_postprocessing_root,
      PATH_POSTPROCESSING_SCRIPTS                 = local.path_postprocessing_scripts,
      FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT = local.filename_postprocessing_scripts_entry_point,
      # TODO Removev this
      CLICKHOUSE_URI    = "http://localhost:8123",
      ELASTICSEARCH_URI = "http://localhost:9200",
      IMAGE_PREFIX      = "IMGPREFIX_REMOVE_ME",
      }
    )
    destination = "${local.path_postprocessing_scripts}/config.sh"
  }
  // Postproduction script launcher
  provisioner "file" {
    source      = "${path.module}/scripts/posvm/launch_pos.sh"
    destination = "${local.path_postprocessing_scripts}/launch_pos.sh"
  }
  // Adjust scripts permissions
  provisioner "remote-exec" {
    inline = [
      "chmod 755 ${local.path_postprocessing_scripts}/launch_pos.sh",
    ]
  }
}
