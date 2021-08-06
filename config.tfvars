# Variables for Sync data
# Attempt eg 21.09.1
release_id_dev                            = "21.08.1"
# Production eg 21.09
release_id_prod                           = "21.08"
gs_sync_from                              = "open-targets-pre-data-releases/21.08.1"

# Variable for creating IMAGES : ElasticSearch and Clickhouse
config_gs_etl                               = "open-targets-pre-data-releases/21.08.1/output"
config_script_name                         = "pos2"
config_release_name                        = "platform21-08-1"

# Project dev info
config_project_id                           = "open-targets-eu-dev"
config_gcp_default_region                   = "europe-west1"
config_gcp_default_zone                     = "europe-west1-d"

config_vm_elastic_search_vcpus              = "4"
config_vm_elastic_search_mem                = "32768"
config_vm_elastic_search_boot_disk_size     = 350
config_vm_elastic_search_version            = "7.9.0"

config_vm_clickhouse_vcpus              = "4"
config_vm_clickhouse_mem                = "26624"
config_vm_clickhouse_boot_disk_size     = 300

config_vm_pos_machine_type                  = "n1-standard-8"
config_vm_pos_boot_image                    = "debian-10"


