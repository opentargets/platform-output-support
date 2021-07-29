## Open Targets: Create ES and CH images.
This module uses the output of ETL to generate the Elasticsearch and Clickhouse images.


> **terraform**: load the configuration files and generates ES and CH images.
 

Eg. deployment_context.tfvars
```
config_release_name                     = "pos"

config_gcp_default_region                   = "europe-west1"
config_gcp_default_zone                     = "europe-west1-d"
config_project_id                           = "open-targets-eu-dev"

config_gs_etl                               = "open-targets-data-releases/21.04/output"

config_vm_elastic_search_vcpus              = "4"
config_vm_elastic_search_mem                = "20480"
config_vm_elastic_search_version            = "7.9.0"
config_vm_elastic_search_boot_disk_size     = 350

config_vm_pos_machine_type                  = "n1-standard-8"
config_vm_pos_boot_image                    = "debian-10"

```

Commands:
```
gcloud auth application-default login
terraform init
terraform plan -var-file="deployment_context.tfvars"
```