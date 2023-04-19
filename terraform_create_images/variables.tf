// --- RELEASE INFORMATION --- //

variable "config_script_name" {
  description = "Open Targets Platform script name, not related to any configuration parameter."
  type = string
}

variable "config_release_name" {
  description = "Open Targets Platform release name, parameter for the images"
  type = string
}

// TODO: remove this variable
variable "config_enable_graphQL" {
  description = "OpenTargets release with graphQL"
  type = bool
  default = true
}

variable "config_gcp_default_region" {
  description = "Default region when not specified in the module"
  type = string
}

variable "config_gcp_default_zone" {
  description = "Default zone when not specified in the module, default 'europe-west1-d'"
  type = string
  default = "europe-west1-d"
}

variable "config_project_id" {
  description = "Default project to use when not specified in the module"
  type = string
}

// --- ETL info --- //
variable "is_partner_instance" {
  description = "Is partners instance? By default false"
  default = false
}

variable "config_gs_etl" {
  description = "Output of the ETL [root]. Eg. open-targets-data-releases/21.04/output"
  type = string
}

variable "config_direct_json" {
  description = "External JSon to laod. Used for SO. Eg. open-targets-data-releases/21.09/input"
  type = string
}

// --- Elastic Search Configuration --- //
variable "config_vm_elastic_boot_image" {
  description = "Boot image configuration for the deployed Elastic Search Instances"
  type = string
  default = "projects/cos-cloud/global/images/family/cos-stable"
}


variable "config_vm_elastic_search_vcpus" {
  description = "CPU count configuration for the deployed Elastic Search Instances"
  type = number
}

variable "config_vm_elastic_search_mem" {
  description = "RAM configuration for the deployed Elastic Search Instances"
  type = number
}

variable "config_vm_elastic_search_version" {
  description = "Elastic search version to deploy"
  type = string
}

variable "config_vm_elastic_search_boot_disk_size" {
  description = "Boot disk size to use for the deployed Elastic Search Instances"
  type = string
}

// --- Clickhouse Configuration --- //

variable "config_vm_clickhouse_boot_image" {
  description = "Boot image configuration for the deployed clickhouse Instances"
  type = string
  default = "debian-10"
}

variable "config_vm_clickhouse_vcpus" {
  description = "CPU count configuration for the deployed clickhouse Instances"
  type = number
}

variable "config_vm_clickhouse_mem" {
  description = "RAM configuration for the deployed clickhouse Instances"
  type = number
}

variable "config_vm_clickhouse_boot_disk_size" {
  description = "Boot disk size to use for the deployed clickhouse Instances"
  type = string
}

// --- GraphQL VM Configuration. Deploy appEngine. If empty doesn't deploy the appEngine --- //
// TODO: remove this variable
variable "config_api_image_version" {
  description = "API Docker image version to use in deployment"
  type = string
  default = ""
}

// TODO: remove this variable
variable "config_appengine_name" {
  description = "AppEngine dev. promote vs no-promote"
  type = string
  default = "pos-api"
}

// --- POS VM Configuration --- //
variable "config_vm_pos_boot_image" {
  description = "Boot image configuration for POS VM, default 'Debian 11'"
  type = string
  default = "debian-11"
}

variable "config_vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '500GB'"
  type = string
  default = 500
}

variable "config_vm_pos_machine_type" {
  description = "Machine type for POS vm, default 'n1-standard-8'"
  type = string
  default = "n1-standard-8"
}
