// Open Targets Platform Infrastructure
// Author: Cinzia Malangone <cinzia.malangone@gmail.com>

// --- Provider Configuration --- //
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.70.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.70.0"
    }
  }
}

provider "google" {
  region = var.config_gcp_default_region
  project = var.config_project_id
}


provider "google-beta" {
  project = var.config_project_id
  region = var.config_gcp_default_region
  #zone   = local.gcp_zone
}

// --- Elastic Search Backend --- //
module "backend_elastic_search" {
  source = "./modules/elasticsearch"
  project_id = var.config_project_id
  module_wide_prefix_scope = "${var.config_script_name}-es"
  // Elastic Search configuration
  vm_elastic_search_version = var.config_vm_elastic_search_version
  vm_elastic_search_vcpus = var.config_vm_elastic_search_vcpus
  // Memory size in MiB
  vm_elastic_search_mem = var.config_vm_elastic_search_mem

  // Region and zone
  vm_default_region = var.config_gcp_default_region
  vm_default_zone = var.config_gcp_default_zone
  vm_elastic_boot_image = var.config_vm_elastic_boot_image
  vm_elasticsearch_boot_disk_size = var.config_vm_elastic_search_boot_disk_size
}

module "backend_clickhouse" {
  source = "./modules/clickhouse"

  module_wide_prefix_scope = "${var.config_script_name}-ch"
  // Elastic Search configuration
  vm_clickhouse_vcpus = var.config_vm_clickhouse_vcpus
  // Memory size in MiB
  vm_clickhouse_mem = var.config_vm_clickhouse_mem
  gs_etl = var.config_gs_etl

  // Region and zone
  project_id = var.config_project_id
  vm_default_region = var.config_gcp_default_region
  vm_default_zone = var.config_gcp_default_zone
  vm_clickhouse_boot_image = var.config_vm_clickhouse_boot_image
  vm_clickhouse_boot_disk_size = var.config_vm_clickhouse_boot_disk_size
}


module "backend_pos_vm" {
  module_wide_prefix_scope = "${var.config_script_name}-vm"
  source = "./modules/posvm"

  project_id = var.config_project_id

  depends_on = [module.backend_elastic_search, module.backend_clickhouse]

  // Region and zone
  vm_default_zone = var.config_gcp_default_zone
  vm_pos_boot_image = var.config_vm_pos_boot_image
  vm_pos_boot_disk_size = var.config_vm_pos_boot_disk_size
  vm_pos_machine_type = var.config_vm_pos_machine_type
  gs_etl = var.config_gs_etl
  is_partner_instance = var.is_partner_instance
  config_direct_json = var.config_direct_json
  vm_elasticsearch_uri = module.backend_elastic_search.elasticsearch_vm_name
  vm_clickhouse_uri = module.backend_clickhouse.clickhouse_vm_name
  release_name = var.config_release_name
}
