locals {
  posvm_remote_user_name = "otops"
  timestamp              = formatdate("YYYYMMDD-hhmm", timestamp())
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
}