resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    vm_pos_boot_disk_size = var.vm_pos_boot_disk_size
    // Take into account the machine type as well
    machine_type = var.vm_pos_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/load_data.sh"))
  }
}


resource "google_compute_instance" "pos_vm" {
  name = "${var.module_wide_prefix_scope}-support-vm-${random_string.random.result}"
  machine_type = var.vm_pos_machine_type
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image =  var.vm_pos_boot_image
      type = "pd-ssd"
      size = var.vm_pos_boot_disk_size
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
        "${path.module}/scripts/load_data.sh",
        {
          PROJECT_ID = var.project_id,
          GC_ZONE = var.vm_default_zone,
          ELASTICSEARCH_URI = var.vm_elasticsearch_uri,
          CLICKHOUSE_URI = var.vm_clickhouse_uri,
          GS_ETL_DATASET = var.gs_etl,
          IS_PARTNER_INSTANCE = var.is_partner_instance,
          GS_DIRECT_FILES = var.config_direct_json,
          IMAGE_PREFIX = var.release_name
        }
      )
    google-logging-enabled = true
  }

  service_account {
    email = "pos-service-account@${var.project_id}.iam.gserviceaccount.com"
    scopes = [ "cloud-platform" ]
  }

  // We add the lifecyle configuration
  lifecycle {
    create_before_destroy = true
  }
}
