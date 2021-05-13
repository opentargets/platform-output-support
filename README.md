# Open Targets: Platform-output-support overview

Platform Output Support (POS) is the third component in the back-end data and infrastructure generation pipeline.
POS is an automatic and unified place to perform a release of OT Platform to the public. The other two components are Platform Input Support (PIS) and the ETL.
POS will be responsible for:

* Infrastructure task
* Publishing datasets in different services
* Data validation


>**terraform**: Infrastructure deployment for the release. Span off an Elasticsearch Server and loads the data into it.

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

# Copyright
Copyright 2018-2021 Open Targets

Bristol Myers Squibb <br>
European Bioinformatics Institute - EMBL-EBI <br>
GSK <br>
Sanofi <br>
Wellcome Sanger Institute <br>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

https://github.com/opentargets/platform-output-support.git
