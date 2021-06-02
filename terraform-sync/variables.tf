// --- Module input parameters --- //
// General deployment input parameters --- //

variable "config_project_id" {
  description = "Default project to use when not specified in the module"
  type = string
  default = "open-targets-eu-dev"
}

variable "module_wide_prefix_scope" {
  description = "The prefix provided here will scope names for those resources created by this module, default 'otpdevsync'"
  type = string
  default = "ot"
}

// --- ETL info --- //
variable "config_gs_etl" {
  description = "Data Release to synch. Eg. open-targets-pre-data-releases/21.04"
  type = string
}

// platform-dev-gs

variable "config_ftp_dir" {
  description = "21.04"
  type = string
}

// --- VM info --- //
variable "config_vm_image" {
  description = "Boot image configuration for POS VM"
  type = string
  default = "debian-10"
}

variable "config_vm_default_zone" {
  description = "Default zone when not specified in the module"
  type = string
  default = "europe-west1-d"
}

variable "config_vm_disk_size" {
  description = "POS VM boot disk size, default '20GB'"
  type = string
  default = 20
}

variable "config_vm_machine_type" {
  description = "Machine type for POS vm"
  type = string
  default = "g1-small"
}

