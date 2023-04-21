locals {
  // --- POS VM Configuration --- //
  // Loging to the remote host, details
  posvm_remote_user_name = "provisioner"
  posvm_remote_path_home = "/home/${local.posvm_remote_user_name}"
  // IAM role to be used to create the VM
  posvm_roles = ["roles/compute.admin", "roles/logging.viewer", "roles/compute.instanceAdmin", "roles/storage.objectViewer", "roles/storage.admin"]
  // VM name
  posvm_name_prefix = "${var.config_release_name}-posvm"
  // Postproduction source provisioning root path
  path_source_postprocessing_scripts                = "${path.module}/scripts/posvm/postproduction"
  path_source_postprocessing_scripts_clickhouse     = "${local.path_source_postprocessing_scripts}/clickhouse"
  path_source_postprocessing_scripts_elastic_search = "${local.path_source_postprocessing_scripts}/elasticsearch"

  // --- POS VM data load process configuration --- //
  // Clickhouse data disk device name
  data_disk_device_name_clickhouse = "clickhouse-data-disk"
  // ElasticSearch data disk device name
  data_disk_device_name_elastic_search = "elastic-search-data-disk"
  // Google Device Disk prefix
  gcp_device_disk_prefix = "/dev/disk/by-id/google-"
  // Clickhouse path to data mount point
  path_mount_data_clickhouse = "/mnt/clickhouse"
  // ElasticSearch path to data mount point
  path_mount_data_elastic_search = "/mnt/elasticsearch"
  // Base path to the postprocessing pipeline scripts
  path_postprocessing_root                               = "/${local.posvm_remote_path_home}/pos"
  path_postprocessing_scripts                            = "/${local.path_postprocessing_root}/scripts"
  path_postprocessing_scripts_clickhouse                 = "/${local.path_postprocessing_scripts}/clickhouse"
  path_postprocessing_scripts_elastic_search             = "/${local.path_postprocessing_scripts}/elasticsearch"
  path_postprocessing_scripts_entry_point_clickhouse     = "/${local.path_postprocessing_scripts_clickhouse}/run.sh"
  path_postprocessing_scripts_entry_point_elastic_search = "/${local.path_postprocessing_scripts_elastic_search}/run.sh"
  // Name of the postprocessing pipeline scripts entry point
  filename_postprocessing_scripts_entry_point = "launch_pos.sh"
  // Flag to signal that the postprocessing pipeline scripts are ready to run
  flag_postprocessing_scripts_ready = "/${local.path_postprocessing_root}/ready"
  // --- [END] POS VM data load process configuration [END] --- //

  // --- Clickhouse specific configuration --- //
  clickhouse_docker_image         = "clickhouse/clickhouse-server"
  clickhouse_docker_image_version = var.config_clickhouse_version
  // --- Disk Images Configuration --- //
  // Time Stamp to be used in the image name
  disk_image_timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
  // Elastic Search disk image name
  disk_image_name_elastic_search = "${var.config_release_name}-${local.disk_image_timestamp}-es"
  // Clickhouse disk image name
  disk_image_name_clickhouse = "${var.config_release_name}-${local.disk_image_timestamp}-ch"

  // --- Labels Configuration --- //
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
}