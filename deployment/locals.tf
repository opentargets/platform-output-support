locals {
  posvm_remote_user_name = "otops"
  timestamp              = formatdate("YYYYMMDD-hhmm", timestamp())
  open_search_disk_name  = "pos-${local.timestamp}-os"
  clickhouse_disk_name   = "pos-${local.timestamp}-ch"

  // --- Labels Configuration --- //
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
}