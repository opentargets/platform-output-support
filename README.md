# Open Targets: Platform-output-support overview

Platform Output Support (POS) is the third component in the back-end data and infrastructure generation pipeline.
POS is part of the Open Targets Platform release process, being responsible for:

* Creation of machine images for the data backend, based on Clickhouse and Elastic Search
* Publishing datasets in different services (Google Cloud and EBI FTP)
* Data validation (**not implemented** yet)

### Requirements
*) Terraform <br>
*) Jq

### How to run the different steps
Simply run the following command:

```make```

The output shows the possible action to run

```
Usage:
  help             show help message
  image            Create Google cloud Clickhouse image and ElasticSearch image.
  clean_image_infrastructure Clean the infrastructure used for creating the data images
  clean_all_image_infrastructure Clean all the infrastructures used for creating data images
  bigquerydev      Big Query Dev
  bigqueryprod     Big Query Production
  sync             Sync the pre-data bucket to private ftp and public ftp
  syncgs           Copy data from pre-release to release 
```

Every single variables is stored in the **config.tfvars**

The current POS steps are:

```make image``` it creates the ES and CH images using the ETL output

```make bigquerydev``` it generates a bigquery dataset in eu-dev

```make bigqueryprod``` it generates a bigquery dataset in production

```make sync``` Sync the data from the Google Storage to EBI FTP (internal use, run from a login node within EBI infrastructure)

```make syncgs``` Sync the data from the google storage pre-release to production (internal use)

```make clean_image_infrastructure``` This step cleans up the infrastructure used for creating the data backend machine images

## Housekeeping

The last step, *clean_image_infrastructure*, will clean up, at infrastructure level, all the resources used for creating the data backend machine images but, if further clean up is needed, e.g. for previous runs of POS that were not properly cleaned up, the following command can be used:

```make clean_all_image_infrastructure```

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
