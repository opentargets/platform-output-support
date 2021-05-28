terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.69.0"
    }
  }
}

provider "google" {
  region = var.config_vm_default_zone
  project = var.config_project_id
}

resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    vm_pos_boot_disk_size = var.config_vm_disk_size
    // Take into account the machine type as well
    machine_type = var.config_vm_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/sync_data.sh"))
  }
}

resource "google_service_account" "gcp_service_acc_apis" {
  //account_id = "${var.module_wide_prefix_scope}-svc-${random_string.random.result}"
  // As we are launching just one VM that we may replace, we can reuse the service account
  account_id = "${var.module_wide_prefix_scope}-svcsnc"
  display_name = "${var.module_wide_prefix_scope}-GCP-service-account"
}


resource "google_compute_instance" "pos_vm" {
  name = "${var.module_wide_prefix_scope}-support-vm-${random_string.random.result}"
  machine_type = var.config_vm_machine_type
  zone   = var.config_vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image =  var.config_vm_image
      type = "pd-ssd"
      size = var.config_vm_disk_size
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
    "${path.module}/scripts/sync_data.sh",
    {
      FTP_PASS = var.ftp_credential
      GS_ETL_DATASET = var.config_gs_etl
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
