resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    vm_elastic_search_version = var.vm_elastic_search_version
  }
}


resource "google_service_account" "gcp_service_acc_apis" {
  account_id = "${var.module_wide_prefix_scope}-svc-${random_string.random.result}"
  display_name = "${var.module_wide_prefix_scope}-GCP-service-account"
}



resource "google_compute_instance" "elasticsearch_etl" {
name = "${var.module_wide_prefix_scope}-elastic-search-template-${random_string.random.result}"
  machine_type = "custom-${var.vm_elastic_search_vcpus}-${var.vm_elastic_search_mem}"
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image =  "${var.vm_elastic_boot_image}"
      type = "pd-ssd"
      size = "${var.vm_elasticsearch_boot_disk_size}"
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
}
