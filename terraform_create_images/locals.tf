locals {
  // --- POS VM Configuration --- //
  // Loging to the remote host, details
  posvm_remote_user_name = "provisioner"
  // IAM role to be used to create the VM
  posvm_roles = ["roles/compute.admin", "roles/logging.viewer", "roles/compute.instanceAdmin", "roles/storage.objectViewer", "roles/storage.admin"]
  // VM name
  posvm_name_prefix = "${var.config_release_name}-posvm"
  // Clickhouse data disk device name
  data_disk_device_name_clickhouse = "clickhouse-data-disk"
  // ElasticSearch data disk device name
  data_disk_device_name_elastic_search = "elastic-search-data-disk"

  // --- Disk Images Configuration --- //
  // Time Stamp to be used in the image name
  disk_image_timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
  // Elastic Search disk image name
  disk_image_name_elastic_search = "${var.config_release_name}-${local.disk_image_timestamp}-es"
  // Clickhouse disk image name
  disk_image_name_clickhouse = "${var.config_release_name}-${local.disk_image_timestamp}-ch"

  // --- Labels Configuration --- //
  base_labels = {
    "team"    = "Open Targets"
    "subteam" = "Backend"
    "product" = "Open Targets Platform"
    "tool"    = "POS"
  }
}