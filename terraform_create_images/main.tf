// Open Targets Platform Infrastructure
// Author: Cinzia Malangone <cinzia.malangone@gmail.com>

// --- Provider Configuration --- //
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.55.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.55.0"
    }
  }
}

provider "google" {
  region  = var.config_gcp_default_region
  project = var.config_project_id
  zone    = var.config_gcp_default_zone
}


provider "google-beta" {
  project = var.config_project_id
  region  = var.config_gcp_default_region
  zone    = var.config_gcp_default_zone
}

// --- Modules --- //
module "backend_pos_vm" {
  module_wide_prefix_scope = "${var.config_script_name}-vm"
  source                   = "./modules/posvm"

  project_id = var.config_project_id

  depends_on = [module.backend_elastic_search, module.backend_clickhouse]

  // Region and zone
  vm_default_zone       = var.config_gcp_default_zone
  vm_pos_boot_image     = var.config_vm_pos_boot_image
  vm_pos_boot_disk_size = var.config_vm_pos_boot_disk_size
  vm_pos_machine_type   = var.config_vm_pos_machine_type
  gs_etl                = var.config_gs_etl
  is_partner_instance   = var.is_partner_instance
  config_direct_json    = var.config_direct_json
  #  vm_elasticsearch_uri  = module.backend_elastic_search.elasticsearch_vm_name
  #  vm_clickhouse_uri     = module.backend_clickhouse.clickhouse_vm_name
  release_name = var.config_release_name
}
