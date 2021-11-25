# Open Targets: Platform-output-support overview

Platform Output Support (POS) is the third component in the back-end data and infrastructure generation pipeline.
POS is an automatic and unified place to perform a release of OT Platform to the public. The other two components are Platform Input Support (PIS) and the ETL.
POS will be responsible for:

* Infrastructure tasks
* Publishing datasets in different services
* Data validation

### Requirement
*) Terraform <br>
*) Jq

### How to run the different steps
Simply run the following command:

```make```

The output shows the possible action to run

```
Usage:
  make 
  help             show help message
  image            Create Google cloud Clickhouse image and ElasticSearch image.
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

```make sync``` Synch the data from the Google Storage to EBI FTP (internal use)

```make syncgs``` Synch the data from the google storage pre-release to production (internal use)

### Infrastructure Tasks

>**directory terraform**: Infrastructure deployment for the release. <br>
*) Spawn an Elasticsearch Server and loads the data into it. <br>
*) Spawn Clickhouse Server and loads the data into it <br>
*) Create Elasticsearch and Clickhouse images <br>


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
