# Open Targets: Platform-output-support overview

Platform Output Support (POS) is the third component in the back-end data and infrastructure generation pipeline.
POS is an automatic and unified place to perform a release of OT Platform to the public. The other two components are Platform Input Support (PIS) and the ETL.
POS will be responsible for:

* Infrastructure tasks
* Publishing datasets in different services
* Data validation

### Infrastructure Tasks

>**directory terraform**: Infrastructure deployment for the release. <br>
*) Spawn an Elasticsearch Server and loads the data into it. <br>
*) Spawn Clickhouse Server and loads the data into it <br>
*) Create Elasticsearch and Clickhouse images <br>
*) Optionally spawn the GraphQL server to query CH and ES 

More details about how to run this task and the config file inside the terraform/README.md

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
