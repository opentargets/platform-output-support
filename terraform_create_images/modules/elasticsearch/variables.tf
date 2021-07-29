// --- Module input parameters --- //
// General deployment input parameters --- //
variable "enable_module" {
  description = "Enable/disable the module ES"
  type = number
  default = 1
}

variable "module_wide_prefix_scope" {
  description = "The prefix provided here will scope names for those resources created by this module, default 'otpdeves'"
  type = string
  default = "otpdeves"
}

variable "project_id" {
  description = "Default project to use when not specified in the module"
  type = string
}

variable "vm_elastic_boot_image" {
  description = "Boot image configuration for the deployed Elastic Search Instances"
  type = string
  default = "projects/cos-cloud/global/images/family/cos-stable"
}

variable "vm_default_region" {
  description = "Default region when not specified in the module"
  type = string
}

variable "vm_default_zone" {
  description = "Default zone when not specified in the module"
  type = string
}

variable "vm_elasticsearch_boot_disk_size" {
  description = "Elastic Search instances boot disk size, default '500GB'"
  type = string
  default = 500
}

variable "vm_elastic_search_version" {
  description = "Elastic Search Docker Image version to use"
  type = string
}

variable "vm_elastic_search_vcpus" {
  description = "CPU count for each Elastic Search Node VM"
  type = number
}

variable "vm_elastic_search_mem" {
  description = "Amount of memory assigned to every Elastic Search Instance (MiB)"
  type = number
}
