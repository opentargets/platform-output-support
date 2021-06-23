resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    vm_elastic_search_version = var.vm_elastic_search_version
    // Take into account changes in the machine type
    vm_machine_type = local.vm_machine_type
  }
}

resource "google_service_account" "gcp_service_acc_apis" {
  //account_id = "${var.module_wide_prefix_scope}-svc-${random_string.random.result}"
  // As we are launching just one VM that we may replace, we can reuse the service account
  account_id = "${var.module_wide_prefix_scope}-svces-${random_string.random.result}"
  display_name = "${var.module_wide_prefix_scope}-GCP-service-account"
}

resource "google_compute_instance" "elasticsearch_etl" {
  // Good, we need randomness in case we make changes in the VM that will replace it
  name = "${var.module_wide_prefix_scope}-server-${random_string.random.result}"
  //machine_type = "custom-${var.vm_elastic_search_vcpus}-${var.vm_elastic_search_mem}"
  // We are launching only one VM, so we can externalise the machine type computation
  machine_type = local.vm_machine_type
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true
  count = var.enable_module

  boot_disk {
    initialize_params {
      image =  var.vm_elastic_boot_image
      type = "pd-ssd"
      size = var.vm_elasticsearch_boot_disk_size
    }
  }

  // WARNING - Does this machine need a public IP?
  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = templatefile(
      "${path.module}/scripts/elasticsearch_startup.sh",
      {
        ELASTIC_SEARCH_VERSION = var.vm_elastic_search_version
      }
    )
    google-logging-enabled = true
  }

  service_account {
    email = google_service_account.gcp_service_acc_apis.email
    scopes = [ "cloud-platform" ]
  }

  // Upon changes to the VM, it will create the new one before getting rid of the previous one
  lifecycle {
    create_before_destroy = true
  }
}
