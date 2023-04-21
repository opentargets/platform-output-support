locals {
  // --- POS VM Configuration --- //
  // Loging to the remote host, details
  posvm_remote_user_name = "provisioner"
  // IAM role to be used to create the VM
  posvm_roles = ["roles/compute.admin", "roles/logging.viewer", "roles/compute.instanceAdmin", "roles/storage.objectViewer", "roles/storage.admin"]
  // VM name
  posvm_name_prefix = "${var.config_release_name}-posvm"
  
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
  path_postprocessing_scripts = "/srv/pos/scripts"
  // Name of the postprocessing pipeline scripts entry point
  filename_postprocessing_scripts_entry_point = "launch_pos.sh"
  // Flag to signal that the postprocessing pipeline scripts are ready to run
  flag_postprocessing_scripts_ready = "/srv/pos/scripts/ready"
  // --- [END] POS VM data load process configuration [END] --- //

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