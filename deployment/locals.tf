locals {
  posvm_remote_user_name = "otops"
  timestamp              = formatdate("YYYYMMDD-hhmm", timestamp())
  open_search_disk_name  = "pos-${local.timestamp}-os"
  clickhouse_disk_name   = "pos-${local.timestamp}-ch"
  platform_release_uri   = "gs://open-targets-pre-data-releases/${var.platform_release_version}"
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
}