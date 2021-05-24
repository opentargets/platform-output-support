// Open Targets Platform Infrastructure
// Author: Cinzia Malangone <cinzia.malangone@gmail.com>

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.55.0"
    }
  }
}

provider "google" {
  region = var.config_gcp_default_region
  project = var.config_project_id
}


// --- Elastic Search Backend --- //
module "backend_elastic_search" {
  source = "./modules/elasticsearch"

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

module "backend_graphql" {
  source = "./modules/graphQL"

  depends_on = [module.backend_elastic_search, module.backend_clickhouse]

  module_wide_prefix_scope = "${var.config_script_name}-gql"
  // GraphQL configuration
  vm_graphql_vcpus = var.config_vm_graphql_vcpus
  // Memory size in MiB
  vm_graphql_mem = var.config_vm_graphql_mem

  // Parameter for GRAPHQL server
  vm_platform_api_image_version = var.config_vm_platform_api_image_version
  host_elastic_search = module.backend_elastic_search.elasticsearch_vm_name
  host_clickhouse = module.backend_clickhouse.clickhouse_vm_name

  // Region and zone
  vm_default_region = var.config_gcp_default_region
  vm_default_zone = var.config_gcp_default_zone
  vm_graphql_boot_image = var.config_vm_graphql_boot_image
  vm_graphql_boot_disk_size = var.config_vm_graphql_boot_disk_size
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
  vm_elasticsearch_uri = module.backend_elastic_search.elasticsearch_vm_name
  vm_clickhouse_uri = module.backend_clickhouse.clickhouse_vm_name
  release_name = var.config_release_name
}
