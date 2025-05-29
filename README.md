# POS — Open Targets Pipeline Output Stage

Create Platform backend (OpenSearch and Clickhouse) and release data.


## Summary

This application uses the [Otter](http://github.com/opentargets/otter) library to
define the steps of the pipeline that consume the output from the data generation pipeline 
and create the backend for the Open Targets Platform. There are also steps for releasing 
data to BigQuery.

Check out the [config.yaml](config/config.yaml) file to see the steps and the tasks that
make them up.


## Installation and running

### Dependencies

- [uv](https://docs.astral.sh/uv/) is the package manager POS. It is compatible
with PIP, so you can also fall back to it if you feel more comfortable.
- [just](https://just.systems/) is the POS interface which is a similar but more suitable alternative to GNU make for this purpose.
- [terraform](https://developer.hashicorp.com/terraform) is the IaC tool by which the necessary infrastructure is assembled and destroyed.


### Recipes

```bash
$ just
Platform Output Support
Set the profile with `just profile=foo <RECIPE>` to use `profiles/foo.tfvars`. Defaults to `profiles/default.tfvars` if no profile is set.
    help
    snapshots    # Create Google cloud disk snapshots (Clickhouse and OpenSearch).
    clean        # Clean the credentials and the infrastructure used for creating the Google cloud disk snapshots
    clean_all
    bigquerydev  # Big Query Dev
    bigqueryprod # Big Query Prod
    gcssync      # Sync data to production Google Cloud Storage
    ftpsync      # Sync data to FTP
```

Private recipes are prefixed with '_' in the [justfile](justfile).

#### Configuring the profile for any of the recipes
All the configuration you need should be possible by modifying a profile such as the [default one](profiles/default.tfvars). 
This file is symlinked to the [terraform.tfvars](deployment/terraform.tfvars) when the recipes are executed. 
If you want to use a different profile, copy/paste the default to foo.tfvars and whenever you run `just` do it like so (the profile param must come _before_ the recipe):
```bash
just profile=foo <RECIPE>` to use `profiles/foo.tfvars`
```

#### Create the data backend for the platform
```bash
just snapshots
```
- starts a Google compute engine with external drives (one for clickhouse, one for opensearch)
- runs the otter steps for croissant, clickhouse and opensearch - see [startup script](deployment/startup.sh)
  - _optional: create tarballs (see [Configuration](#configuration)) 

#### Release data to BigQuery
```bash
# dev
just bigquerydev

# prod
just bigqueryprod
```
- creates a local otter config based on the terraform.tfvars profile. 
- runs the otter step for releasing to Google BigQuery.
  
#### Release data to FTP
```bash
just ftpsync
```
- uses the terraform.tfvars profile as configuration.
- runs a shell script that runs a gcloud container on the EBI HPC.
- from the container it syncs the data from GCS to the EBI FTP.
  
#### Release data to GCS
```bash
just gcssync
```
- uses the terraform.tfvars profile as configuration.
- runs a gcloud command to sync one GCS with another.


### Configuration

You should only ever need to configure the terraform profile. This is used as the point of configuration even where terraform is not actually used.
See [here](#configuring-the-profile-for-any-of-the-recipes) for details. 

Terraform will apply this configuration, or in the cases where terraform is not used, an HCL library will read and apply the configuration as needed.

A folder for all the configuration is [here](config), which has the following:

- Main config for otter: [config.yaml](config/config.yaml)
- Config for datasets, data sources/table names/settings etc. for Clickhouse, OpenSearch, BigQuery: [datasets.yaml](config/datasets.yaml)
- Clickhouse configs/schema/sql: [clickhouse](config/clickhouse/)
- OpenSearch Dockerfile/index settings: [opensearch](config/opensearch/)

It's configured by default to load all the necessary datasets, but it can be modified. Make sure that the dataset names in the config.yaml have a corresponding entry in the datasets.yaml and so on.


## Copyright

Copyright 2014-2025 EMBL - European Bioinformatics Institute, Genentech, GSK,
MSD, Pfizer, Sanofi and Wellcome Sanger Institute

This software was developed as part of the Open Targets project. For more
information please see: http://www.opentargets.org

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.