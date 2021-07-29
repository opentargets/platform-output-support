resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    // Take into account changes in the machine type
    vm_machine_type = local.vm_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/clickhouse_startup.sh"))
  }
}

// resource "google_service_account": info about the standard unique


//resource "google_project_iam_member" "main" {
//  project = var.project_id
//  role    = "roles/compute.instanceAdmin"
//  member  = "serviceAccount:${google_service_account.gcp_service_acc_apis.email}"
//}

resource "google_compute_instance" "clickhouse_etl" {
  // Good, we need randomness in case we make changes in the VM that will replace it
  name = "${var.module_wide_prefix_scope}-server-${random_string.random.result}"
  // We are launching only one VM, so we can externalise the machine type computation
  machine_type = local.vm_machine_type
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true
  count = var.enable_module

  boot_disk {
    initialize_params {
      image =  var.vm_clickhouse_boot_image
      type = "pd-ssd"
      size = var.vm_clickhouse_boot_disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = templatefile(
   "${path.module}/scripts/clickhouse_startup.sh",
      {
      PROJECT_ID = var.project_id,
      GC_ZONE = var.vm_default_zone,
      GS_ETL_DATASET = var.gs_etl
    }
    )
    google-logging-enabled = true
  }


  service_account {
    email = "pos-service-account@${var.project_id}.iam.gserviceaccount.com"
    scopes = [ "cloud-platform" ]
  }

  // Upon changes to the VM, it will create the new one before getting rid of the previous one
  lifecycle {
    create_before_destroy = true
  }
}
