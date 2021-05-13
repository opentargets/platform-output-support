// --- RELEASE INFORMATION --- //
variable "config_release_name" {
  description = "Open Targets Platform release name, not related to any configuration parameter."
  type = string
}

variable "config_gcp_default_region" {
  description = "Default region when not specified in the module"
  type = string
}

variable "config_gcp_default_zone" {
  description = "Default zone when not specified in the module"
  type = string
}

variable "config_project_id" {
  description = "Default project to use when not specified in the module"
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
