// This file defines the VM used for post-production, i.e. for creating the data disk images, a.k.a. POS VM.

// This random with keepers is here just for development purposes, as running POS should be a disposable process.
resource "random_string" "posvm" {
  length  = 8
  lower   = true
  upper   = false
  special = false
  keepers = {
    vm_pos_boot_disk_size = var.vm_pos_boot_disk_size
    // Take into account the machine type as well
    machine_type = var.vm_pos_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/posvm/startup.sh"))
  }
}


resource "google_compute_instance" "posvm" {
  project                   = var.config_project_id
  name                      = "${local.posvm_name_prefix}-${random_string.posvm.result}"
  machine_type              = var.vm_pos_machine_type
  zone                      = var.vm_default_zone
  allow_stopping_for_update = true
  // TODO This should be set to false
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = var.vm_pos_boot_image
      type  = "pd-ssd"
      size  = var.vm_pos_boot_disk_size
    }
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
      "${path.module}/scripts/startup.sh",
      {
        PROJECT_ID          = var.project_id,
        GC_ZONE             = var.vm_default_zone,
        GS_ETL_DATASET      = var.gs_etl,
        IS_PARTNER_INSTANCE = var.is_partner_instance,
        GS_DIRECT_FILES     = var.config_direct_json,
        DISK_IMAGE_NAME_CH  = local.image_name_clickhouse,
        DISK_IMAGE_NAME_ES  = local.image_name_elastic_search,
      }
    )
    google-logging-enabled = true
  }

  service_account {
    email  = "pos-service-account@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  // We add the lifecyle configuration
  lifecycle {
    create_before_destroy = true
  }
}
