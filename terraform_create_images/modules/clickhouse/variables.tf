// --- Module input parameters --- //
// General deployment input parameters --- //
variable "enable_module" {
  description = "Enable/disable the module CH"
  type = number
  default = 1
}

variable "module_wide_prefix_scope" {
  description = "The prefix provided here will scope names for those resources created by this module, default 'otpdevch'"
  type = string
  default = "otpdevch"
}

variable "project_id" {
  description = "Default project to use when not specified in the module"
  type = string
}

variable "vm_clickhouse_boot_image" {
  description = "Boot image configuration for the deployed Clickhouse Instances"
  type = string
  default = "debian-10"
}

variable "vm_default_region" {
  description = "Default region when not specified in the module"
  type = string
}

variable "vm_default_zone" {
  description = "Default zone when not specified in the module"
  type = string
}

variable "vm_clickhouse_boot_disk_size" {
  description = "Clickhouse instances boot disk size, default '500GB'"
  type = string
  default = 300
}

variable "vm_clickhouse_vcpus" {
  description = "CPU count for each Clickhouse Node VM"
  type = number
}

variable "vm_clickhouse_mem" {
  description = "Amount of memory assigned to every Clickhouse Instance (MiB)"
  type = number
}

variable "gs_etl" {
  description = "Output of the ETL [root]. Eg. open-targets-data-releases/21.04/output"
  type = string
}