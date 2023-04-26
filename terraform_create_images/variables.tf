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


// --- RELEASE INFORMATION --- //

variable "config_script_name" {
  description = "Open Targets Platform script name, not related to any configuration parameter."
  type        = string
  default     = "pos-unset"
}

variable "config_release_name" {
  description = "Open Targets Platform release name, parameter for the images"
  type        = string
  default     = "pos-unset"
}

// TODO: remove this variable
variable "config_enable_graphQL" {
  description = "OpenTargets release with graphQL"
  type        = bool
  default     = true
}

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

variable "config_repo_branch_pos" {
  description = "Open Targets Platform Output Support repository branch, parameter for building the images, default 'main'"
  type        = string
  default     = "main"
}

// --- ETL info --- //
variable "is_partner_instance" {
  description = "Is partners instance? By default false"
  type        = bool
  default     = false
}

variable "config_gs_etl" {
  description = "Output of the ETL [root]. Eg. open-targets-data-releases/21.04/output"
  type        = string
}

variable "config_direct_json" {
  description = "External JSon to laod. Used for SO. Eg. open-targets-data-releases/21.09/input"
  type        = string
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
  description = "Elastic search docker image version to deploy"
  type        = string
  default     = "7.13.4"
}

variable "elastic_search_data_disk_size" {
  description = "Elastic search data disk size to deploy"
  type        = string
  default     = "128"
}










// --- REMOVE FROM HERE --- //
// --- Elastic Search Configuration --- //
variable "config_vm_elastic_boot_image" {
  description = "Boot image configuration for the deployed Elastic Search Instances"
  type        = string
  default     = "projects/cos-cloud/global/images/family/cos-stable"
}


variable "config_vm_elastic_search_vcpus" {
  description = "CPU count configuration for the deployed Elastic Search Instances"
  type        = number
}

variable "config_vm_elastic_search_mem" {
  description = "RAM configuration for the deployed Elastic Search Instances"
  type        = number
}

variable "config_vm_elastic_search_version" {
  description = "Elastic search version to deploy"
  type        = string
}

variable "config_vm_elastic_search_boot_disk_size" {
  description = "Boot disk size to use for the deployed Elastic Search Instances"
  type        = string
}

// --- Clickhouse Configuration --- //


variable "config_vm_clickhouse_vcpus" {
  description = "CPU count configuration for the deployed clickhouse Instances"
  type        = number
}

variable "config_vm_clickhouse_mem" {
  description = "RAM configuration for the deployed clickhouse Instances"
  type        = number
}

variable "config_vm_clickhouse_boot_disk_size" {
  description = "Boot disk size to use for the deployed clickhouse Instances"
  type        = string
}

// --- GraphQL VM Configuration. Deploy appEngine. If empty doesn't deploy the appEngine --- //
// TODO: remove this variable
variable "config_api_image_version" {
  description = "API Docker image version to use in deployment"
  type        = string
  default     = ""
}

// TODO: remove this variable
variable "config_appengine_name" {
  description = "AppEngine dev. promote vs no-promote"
  type        = string
  default     = "pos-api"
}
