variable "vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '600GB'"
  type        = string
  default     = 600
}

variable "vm_pos_machine_type" {
  description = "Machine type for POS vm, default 'n2-highmem-96'"
  type        = string
  default     = "n2-highmem-96"
}

variable "pos_logs_path_root" {
  description = "GCS root path where POS pipeline logs will be uploaded for the different POS sessions, default 'gs://open-targets-ops/logs/platform-pos'"
  type        = string
  default     = "gs://open-targets-ops/logs/platform-pos"
}

variable "clickhouse_data_disk_size" {
  description = "Clickhouse data disk size to deploy"
  type        = string
  default     = "128"
}

variable "clickhouse_snapshot" {
  description = "Snapshot to use for Clickhouse data disk"
  type        = string
  default     = null
}

variable "open_search_data_disk_size" {
  description = "Opensearch data disk size to deploy"
  type        = string
  default     = "256"
}

variable "open_search_snapshot" {
  description = "Snapshot to use for OpenSearch data disk"
  type        = string
  default     = null
}

variable "pos_git_branch" {
    description = "Git branch to use for POS deployment"
    type        = string
    default     = "main"
}