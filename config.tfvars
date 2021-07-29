release_id                                 = "21.06.testc"
release_id_prod                            = "21.06"
# Without prefix gs.
config_gs_etl                               = "open-targets-pre-data-releases/21.06.6.1/output"
config_project_id                           = "open-targets-eu-dev"

config_script_name                         = "pos2"
config_release_name                        = "platform21-06-5-1"
config_enable_graphQL                      = false

config_gcp_default_region                   = "europe-west1"
config_gcp_default_zone                     = "europe-west1-d"

config_vm_elastic_search_vcpus              = "4"
config_vm_elastic_search_mem                = "32768"
config_vm_elastic_search_boot_disk_size     = 350
config_vm_elastic_search_version            = "7.9.0"

config_vm_pos_machine_type                  = "n1-standard-8"
config_vm_pos_boot_image                    = "debian-10"

config_vm_clickhouse_vcpus              = "4"
config_vm_clickhouse_mem                = "26624"
config_vm_clickhouse_boot_disk_size     = 300

config_vm_graphql_vcpus              = "4"
config_vm_graphql_mem                = "7680"
config_vm_graphql_boot_disk_size     = 30
config_vm_platform_api_image_version = "21.06.5"
