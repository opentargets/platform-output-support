variable "vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '500GB'"
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
  default     = "200"
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

variable "clickhouse_backup_base_path" {
  description = "Base path in GCS bucket where ClickHouse backups will be stored"
  type        = string
  default     = "https://storage.googleapis.com/open-targets-data-backends/clickhouse/"
}

variable "database_namespace" {
  description = "Database namespace, default 'ot'"
  type        = string
  default     = "ot"
}

variable "open_search_data_disk_size" {
  description = "Opensearch data disk size to deploy"
  type        = string
  default     = "400"
}

variable "open_search_snapshot_source" {
  description = "Snapshot to use for OpenSearch data disk source"
  type        = string
  default     = null
}

variable "open_search_snapshot_repository" {
  description = "OpenSearch snapshot repository name"
  type        = string
  default     = "ot-os-snapshots"
}

variable "open_search_snapshot_bucket" {
  description = "OpenSearch snapshot bucket name"
  type        = string
  default     = "open-targets-data-backends"
}

variable "open_search_snapshot_base_path" {
  description = "OpenSearch snapshot base path"
  type        = string
  default     = "opensearch"
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

variable "pos_log_level" {
  description = "Log level for POS"
  type        = string
  default     = "INFO"
}

variable "release_id" {
  description = "Platform release version"
  type        = string
  default     = "dev"
}

variable "open_search_image_tag" {
  description = "OpenSearch image tag"
  type        = string
  default     = "3.1.0"
}

variable "open_search_jvm_options" {
  description = "OpenSearch JVM options"
  type        = string
  default     = "-Xms302g -Xmx304g"
}

variable "clickhouse_image_tag" {
  description = "Clickhouse image tag"
  type        = string
  default     = "25.6.3.116"
}

variable "data_location_source" {
  description = "GCS data source"
  type        = string
  default     = "gs://open-targets-pre-data-releases/dev"
}

variable "data_location_production" {
  description = "GCS data production"
  type        = string
  default     = "gs://open-targets-data-releases/prod"
}

variable "ftp_location" {
  description = "FTP location for the data release"
  type        = string
  default     = "http://ftp.ebi.ac.uk/pub/databases/opentargets/platform"
}

variable "is_ppp" {
  description = "Is this a partner preview pipeline?"
  type        = bool
  default     = false
}