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

variable "clickhouse_snapshot_source" {
  description = "Snapshot to use for Clickhouse data disk source"
  type        = string
  default     = null
}

variable "clickhouse_tarball" {
  description = "Whether to make the clickhouse tarball, default 'false'"
  type        = bool
  default     = false
}

variable "open_search_data_disk_size" {
  description = "Opensearch data disk size to deploy"
  type        = string
  default     = "256"
}

variable "open_search_snapshot_source" {
  description = "Snapshot to use for OpenSearch data disk source"
  type        = string
  default     = null
}

variable "open_search_tarball" {
  description = "Whether to make the opensearch tarball, default 'false'"
  type        = bool
  default     = false
}

variable "pos_git_branch" {
  description = "Git branch to use for POS deployment"
  type        = string
  default     = "main"
}

# ---- POS scratchpad config ---- #

variable "platform_release_version" {
  description = "Platform release version"
  type        = string
  default     = "dev"
}

variable "open_search_image_tag" {
  description = "OpenSearch image tag"
  type        = string
  default     = "2.19.0"
}

variable "open_search_jvm_options" {
  description = "OpenSearch JVM options"
  type        = string
  default     = "-Xms302g -Xmx304g"
}

variable "clickhouse_image_tag" {
  description = "Clickhouse image tag"
  type        = string
  default     = "23.3.1.2823"
}