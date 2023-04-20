// --- Module input parameters --- //
// General deployment input parameters --- //

variable "project_id" {
  description = "Default project to use when not specified in the module"
  type        = string
}

variable "enable_graphQL" {
  description = "OpenTargets release with graphQL"
  type        = bool
  default     = true
}

variable "module_wide_prefix_scope" {
  description = "The prefix provided here will scope names for those resources created by this module, default 'otpdeves'"
  type        = string
  default     = "otdevpos"
}

variable "release_name" {
  description = "Open Targets Platform release name, parameter for the images"
  type        = string
}

// --- ETL info --- //
variable "is_partner_instance" {
  description = "Is partners instance? By default false"
  default     = false
}

variable "gs_etl" {
  description = "Output of the ETL [root]. Eg. open-targets-data-releases/21.04/output"
  type        = string
}

variable "config_direct_json" {
  description = "External JSon to laod. Used for SO. Eg. open-targets-data-releases/21.09"
  type        = string
}

// --- VM info --- //
variable "vm_pos_boot_image" {
  description = "Boot image configuration for POS VM"
  type        = string
  default     = "debian-10"
}

variable "vm_default_zone" {
  description = "Default zone when not specified in the module"
  type        = string
}

variable "vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '500GB'"
  type        = string
  default     = 500
}

variable "vm_pos_machine_type" {
  description = "Machine type for POS vm"
  type        = string
}

variable "vm_elasticsearch_uri" {
  description = "Elasticsearch Server"
  type        = string
}

variable "vm_clickhouse_uri" {
  description = "Clickhouse Server"
  type        = string
}

variable "git_branch" {
  description = "Git branch to aquire SQL scripts from: useful for developing on feature branches."
  type        = string
  default     = "main"
}
