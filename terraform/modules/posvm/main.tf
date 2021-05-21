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


resource "google_service_account" "gcp_service_acc_apis" {
  //account_id = "${var.module_wide_prefix_scope}-svc-${random_string.random.result}"
  // We are launching a single VM, even with multiple VMs, we can reuse the same account
  account_id = "${var.module_wide_prefix_scope}-svcpos"
  display_name = "${var.module_wide_prefix_scope}-GCP-service-account"
}



resource "google_compute_instance" "pos_vm" {
  name = "${var.module_wide_prefix_scope}-support-vm-${random_string.random.result}"
  machine_type = var.vm_pos_machine_type
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true
  count = var.enable_module

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
          ELASTICSEARCH_URI = var.vm_elasticsearch_uri,
          GS_ETL_DATASET = var.gs_etl
        }
      )
    google-logging-enabled = true
  }


  service_account {
    email = google_service_account.gcp_service_acc_apis.email
    scopes = [ "cloud-platform" ]
  }

  // We add the lifecyle configuration
  lifecycle {
    create_before_destroy = true
  }
}
