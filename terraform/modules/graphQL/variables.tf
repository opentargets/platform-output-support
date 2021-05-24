variable "enable_module" {
  description = "Enable/disable the module GraphQL"
  type = number
  default = 1
}

variable "module_wide_prefix_scope" {
  description = "The prefix provided here will scope names for those resources created by this module, default 'otpdevch'"
  type = string
  default = "otpdevgql"
}

variable "vm_platform_api_image_version" {
  description = "API Docker image version to use in deployment"
  type = string
}

variable "host_clickhouse" {
  description = "Clickhouse HOSTNAME"
  type = string
}

variable "host_elastic_search" {
  description = "ELASTICSEARCH HOSTNAME"
  type = string
}

variable "vm_graphql_boot_image" {
  description = "Boot image configuration for the deployed graphql Instances"
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

variable "vm_graphql_boot_disk_size" {
  description = "graphql instances boot disk size, default '500GB'"
  type = string
  default = 300
}

variable "vm_graphql_vcpus" {
  description = "CPU count for each graphql Node VM"
  type = number
}

variable "vm_graphql_mem" {
  description = "Amount of memory assigned to every graphql Instance (MiB)"
  type = number
}
