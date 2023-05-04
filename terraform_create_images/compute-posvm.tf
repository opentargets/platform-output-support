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

// Key pair for SSH access
resource "tls_private_key" "posvm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create a disk volume for Clickhouse data
resource "google_compute_disk" "clickhouse_data_disk" {
  project     = var.project_id
  name        = local.disk_image_name_clickhouse
  description = "Clickhouse data disk"
  type        = "pd-ssd"
  zone        = var.gcp_default_zone
  size        = var.clickhouse_data_disk_size
  labels      = local.base_labels
}

// Create a disk volume for ElasticSearch data
resource "google_compute_disk" "elastic_search_data_disk" {
  project     = var.project_id
  name        = local.disk_image_name_elastic_search
  description = "ElasticSearch data disk"
  type        = "pd-ssd"
  zone        = var.gcp_default_zone
  size        = var.elastic_search_data_disk_size
  labels      = local.base_labels
}



// POS VM instance definition
resource "google_compute_instance" "posvm" {
  project                   = var.project_id
  name                      = "${local.posvm_name_prefix}-${random_string.posvm.result}"
  machine_type              = var.vm_pos_machine_type
  zone                      = var.gcp_default_zone
  allow_stopping_for_update = true
  // TODO This should be set to false
  can_ip_forward = true

  scheduling {
    automatic_restart   = !var.vm_pos_machine_spot
    on_host_maintenance = var.vm_pos_machine_spot ? "TERMINATE" : "MIGRATE"
    preemptible         = var.vm_pos_machine_spot
    provisioning_model  = var.vm_pos_machine_spot ? "SPOT" : "STANDARD"
    instance_termination_action = var.vm_pos_machine_spot ? "STOP" : null
  }

  boot_disk {
    initialize_params {
      image = var.vm_pos_boot_image
      type  = "pd-ssd"
      size  = var.vm_pos_boot_disk_size
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
        PROJECT_ID                                  = var.project_id,
        GC_ZONE                                     = var.gcp_default_zone,
        GS_ETL_DATASET                              = var.config_gs_etl,
        IS_PARTNER_INSTANCE                         = var.is_partner_instance,
        GS_DIRECT_FILES                             = var.config_direct_json,
        GCP_DEVICE_DISK_PREFIX                      = local.gcp_device_disk_prefix,
        POS_USER_NAME                               = local.posvm_remote_user_name
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
    email  = "pos-service-account@${var.project_id}.iam.gserviceaccount.com"
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
    content = templatefile("${local.path_source_postprocessing_scripts}/config.sh", {
      POS_PROJECT_ID                                             = var.project_id,
      POS_GCP_ZONE                                                = var.gcp_default_zone,
      POS_GS_ETL_DATASET                                         = var.config_gs_etl,
      POS_IS_PARTNER_INSTANCE                                    = var.is_partner_instance,
      POS_GS_DIRECT_FILES                                        = var.config_direct_json,
      POS_GCP_DEVICE_DISK_PREFIX                                 = local.gcp_device_disk_prefix,
      POS_DATA_DISK_DEVICE_NAME_CH                               = local.data_disk_device_name_clickhouse,
      POS_DATA_DISK_DEVICE_NAME_ES                               = local.data_disk_device_name_elastic_search,
      POS_DISK_IMAGE_NAME_CH                                     = local.disk_image_name_clickhouse,
      POS_DISK_IMAGE_NAME_ES                                     = local.disk_image_name_elastic_search,
      POS_PATH_MOUNT_DATA_CLICKHOUSE                             = local.path_mount_data_clickhouse,
      POS_PATH_MOUNT_DATA_ELASTICSEARCH                          = local.path_mount_data_elastic_search,
      POS_PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE                 = local.path_postprocessing_scripts_clickhouse,
      POS_PATH_POSTPROCESSING_SCRIPTS_ELASTIC_SEARCH             = local.path_postprocessing_scripts_elastic_search,
      POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_CLICKHOUSE     = local.path_postprocessing_scripts_entry_point_clickhouse,
      POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_ELASTIC_SEARCH = local.path_postprocessing_scripts_entry_point_elastic_search,
      POS_DATA_RELEASE_SEKELETON_PATH_OUTPUT_ROOT                = local.data_release_skeleton_path_output_root,
      POS_DATA_RELEASE_SEKELETON_PATH_INPUT_ROOT                 = local.data_release_skeleton_path_input_root,
      POS_DATA_RELEASE_SEKELETON_PATH_ETL_ROOT                   = local.data_release_skeleton_path_etl_root,
      POS_DATA_RELEASE_SEKELETON_PATH_ETL_JSON_ROOT              = local.data_release_skeleton_path_etl_json_root,
      POS_DATA_RELEASE_SEKELETON_PATH_ETL_PARQUET_ROOT           = local.data_release_skeleton_path_etl_parquet_root,
      POS_DATA_RELEASE_PATH_SOURCE_ROOT                          = local.data_release_path_source_root,
      POS_DATA_RELEASE_PATH_ETL_JSON                             = local.data_release_path_etl_json,
      POS_DATA_RELEASE_PATH_ETL_PARQUET                          = local.data_release_path_etl_parquet,
      POS_DATA_RELEASE_PATH_INPUT_ROOT                           = local.data_release_path_input_root,
      POS_CLICKHOUSE_DOCKER_IMAGE                                = local.clickhouse_docker_image,
      POS_CLICKHOUSE_DOCKER_IMAGE_VERSION                        = local.clickhouse_docker_image_version,
      POS_ELASTIC_SEARCH_DOCKER_IMAGE                            = local.elastic_search_docker_image,
      POS_ELASTIC_SEARCH_DOCKER_IMAGE_VERSION                    = local.elastic_search_docker_image_version,
      POS_DATA_DISK_TARBALL_CLICKHOUSE                           = var.pos_ch_tarball_name,
      POS_DATA_DISK_TARBALL_ELASTIC_SEARCH                       = var.pos_es_tarball_name,
      POS_POS_REPO_BRANCH                                        = var.config_repo_branch_pos,
      POS_FLAG_POSTPROCESSING_SCRIPTS_READY                      = local.flag_postprocessing_scripts_ready,
      POS_GCP_PATH_POS_PIPELINE_SESSION_LOGS                     = local.gcp_path_pos_pipeline_session_logs,
      POS_PATH_POSTPROCESSING_ROOT                               = local.path_postprocessing_root,
      POS_PATH_POSTPROCESSING_SCRIPTS                            = local.path_postprocessing_scripts,
      POS_FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT            = local.filename_postprocessing_scripts_entry_point,
      # TODO Removev this
      POS_CLICKHOUSE_URI    = "http://localhost:8123",
      POS_ELASTICSEARCH_URI = "http://localhost:9200",
      POS_IMAGE_PREFIX      = "IMGPREFIX_REMOVE_ME",
      }
    )
    destination = "${local.path_postprocessing_scripts}/config.sh"
  }
  // Postproduction script launcher
  provisioner "file" {
    source      = "${local.path_source_postprocessing_scripts}/launch_pos.sh"
    destination = "${local.path_postprocessing_scripts}/launch_pos.sh"
  }
  // Adjust scripts permissions
  provisioner "remote-exec" {
    inline = [
      "chmod 755 ${local.path_postprocessing_scripts}/launch_pos.sh",
    ]
  }
  // Provision the operations extensions for BASH
  provisioner "file" {
    source      = "${local.path_source_postprocessing_scripts}/ops.bashrc"
    destination = "${local.path_postprocessing_scripts}/ops.bashrc"
  }
  // Tell BASH to load the operations extensions
  provisioner "remote-exec" {
    inline = [
      "echo \"source ${local.path_postprocessing_scripts}/ops.bashrc\" >> ~/.bashrc",
    ]
  }
  // Provision the postproduction scripts for Clickhouse
  provisioner "file" {
    source      = local.path_source_postprocessing_scripts_clickhouse
    destination = local.path_postprocessing_scripts_clickhouse
  }
  // Make Clickhouse postproduction scripts executable
  provisioner "remote-exec" {
    inline = [
      "find ${local.path_postprocessing_scripts_clickhouse} -type f -iname \"*.sh\" -exec chmod 755 {} \\;",
    ]
  }
  // Provision the postproduction scripts for Elastic Search
  provisioner "file" {
    source      = local.path_source_postprocessing_scripts_elastic_search
    destination = local.path_postprocessing_scripts_elastic_search
  }
  // Make Elastic Search postproduction scripts executable
  provisioner "remote-exec" {
    inline = [
      "find ${local.path_postprocessing_scripts_elastic_search} -type f -iname \"*.sh\" -exec chmod 755 {} \\;",
    ]
  }
  // Set the 'ready' flag for the postprocessing pipeline to start
  provisioner "remote-exec" {
    inline = [
      "touch ${local.flag_postprocessing_scripts_ready}",
    ]
  }
}
