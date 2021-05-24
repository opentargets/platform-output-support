resource "random_string" "random" {
  length = 8
  lower = true
  upper = false
  special = false
  keepers = {
    // Take into account changes in the machine type
    vm_machine_type = local.vm_machine_type
    // Be aware of launch script changes
    launch_script_hash = md5(file("${path.module}/scripts/instance_startup.sh"))
  }
}

resource "google_service_account" "gcp_service_acc_apis" {
  //account_id = "${var.module_wide_prefix_scope}-svc-${random_string.random.result}"
  // As we are launching just one VM that we may replace, we can reuse the service account
  account_id = "${var.module_wide_prefix_scope}-svcgql"
  display_name = "${var.module_wide_prefix_scope}-GCP-service-account"
}


resource "google_compute_firewall" "default" {
  name    = "graphql-app-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080", "80"]
  }
}

resource "google_compute_instance" "graphql_instance" {
  // Good, we need randomness in case we make changes in the VM that will replace it
  name = "${var.module_wide_prefix_scope}-server-${random_string.random.result}"
  // We are launching only one VM, so we can externalise the machine type computation
  machine_type = local.vm_machine_type
  zone   = var.vm_default_zone
  allow_stopping_for_update = true
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image =  var.vm_graphql_boot_image
      type = "pd-ssd"
      size = var.vm_graphql_boot_disk_size
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
    "${path.module}/scripts/instance_startup.sh",
    {
      SLICK_CLICKHOUSE_URL = "jdbc:clickhouse://${var.host_clickhouse}:8123",
      ELASTICSEARCH_HOST = var.host_elastic_search,
      PLATFORM_API_VERSION = var.vm_platform_api_image_version,
      OTP_API_PORT = local.otp_api_port
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









