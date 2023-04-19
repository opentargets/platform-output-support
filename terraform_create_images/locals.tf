locals {
  // Loging to the remote host, details
  remote_user_name = "provisioner"
  // Time Stamp to be used in the image name
  image_timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
  // Elastic Search disk image name
  image_name_elastic_search = "${var.config_release_name}-${local.image_timestamp}-es"
  // Clickhouse disk image name
  image_name_clickhouse = "${var.config_release_name}-${local.image_timestamp}-ch"
}