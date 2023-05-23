// --- Refactoring POS configuration --- //

variable "resources_prefix" {
  description = "Prefix to use for all resources deployed in the cloud, default 'pos-unset'"
  type        = string
  default     = "pos-unset"
}
variable "data_images_prefix" {
  description = "Prefix to use for all data images created by this postprocessing pipeline, default 'pos-unset'"
  type        = string
  default     = "pos-unset"
}
variable "data_location_source" {
  description = "Source location for the data release being processed, default 'open-targets-pre-data-releases/dev'"
  type        = string
  default     = "open-targets-pre-data-releases/dev"
}
variable "data_location_production" {
  description = "Location where the data release being processed will be stored for production, default 'open-targets-data-releases/dev'"
  type        = string
  default     = "open-targets-data-releases/dev"
}
variable "project_id" {
  description = "GCP project where the resources will be deployed, default 'open-targets-eu-dev'"
  type        = string
  default     = "open-targets-eu-dev"
}
variable "gcp_default_region" {
  description = "GCP region where the resources will be deployed, default 'europe-west1'"
  type        = string
  default     = "europe-west1"
}
variable "gcp_default_zone" {
  description = "GCP zone where the resources will be deployed, default 'europe-west1-d'"
  type        = string
  default     = "europe-west1-d"
}
variable "is_public_data_images" {
  description = "This flag signals where the produced data images should be made publicly available, default 'false'"
  type        = bool
  default     = false
}

// --- Data Images --- //
variable "pos_ch_tarball_name" {
  description = "Filename for the tarball release of the Clickhouse data image"
  type        = string
  default     = "clickhouse.tgz"
}

variable "pos_es_tarball_name" {
  description = "Filename for the tarball release of the Elastic Search data image"
  type        = string
  default     = "elastic_search.tgz"
}


// --- RELEASE INFORMATION --- //
variable "config_gcp_default_region" {
  description = "Default region when not specified in the module"
  type        = string
  default     = "europe-west1"
}

variable "config_gcp_default_zone" {
  description = "Default zone when not specified in the module, default 'europe-west1-d'"
  type        = string
  default     = "europe-west1-d"
}

variable "config_project_id" {
  description = "Default project to use when not specified in the module, default 'open-targets-eu-dev'"
  type        = string
  default     = "open-targets-eu-dev"
}

// --- ETL info --- //
variable "is_partner_instance" {
  description = "Is partners instance? By default false"
  type        = bool
  default     = false
}

// --- POS VM Configuration --- //
variable "vm_pos_boot_image" {
  description = "Boot image configuration for POS VM, default 'Debian 11'"
  type        = string
  default     = "debian-11"
}

variable "vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '64GB'"
  type        = string
  default     = 64
}

variable "vm_pos_machine_type" {
  description = "Machine type for POS vm, default 'n1-standard-8'"
  type        = string
  default     = "n1-standard-8"
}

variable "vm_pos_machine_spot" {
  description = "Should SPOT provisioning model be used for POS VM?, default 'false'"
  type        = bool
  default     = false
}

variable "pos_logs_path_root" {
  description = "GCS root path where POS pipeline logs will be uploaded for the different POS sessions, default 'gs://open-targets-ops/logs/platform-pos'"
  type        = string
  default     = "gs://open-targets-ops/logs/platform-pos"
}

// --- Clickhouse Configuration --- //
variable "clickhouse_docker_image_version" {
  description = "Clickhouse docker image version to deploy, default '23.3.1.2823'"
  type        = string
  default     = "23.3.1.2823"
}

variable "clickhouse_data_disk_size" {
  description = "Clickhouse data disk size to deploy"
  type        = string
  default     = "64"
}

// --- Elastic Search Configuration --- //
variable "elastic_search_docker_image_version" {
  description = "Elastic search docker image version to deploy, default '7.10.2'"
  type        = string
  default     = "7.10.2"
}

variable "elastic_search_data_disk_size" {
  description = "Elastic search data disk size to deploy"
  type        = string
  default     = "128"
}
