# POS — Open Targets Pipeline Output Stage

Create Platform backend (OpenSearch and Clickhouse) and release data.


## Summary

This application uses the [Otter](http://github.com/opentargets/otter) library to
define the steps of the pipeline that create and push all the output artifacts for a run of the Open Targets pipeline.

Check out the [config.yaml](config/config.yaml) file to see the steps and the tasks that
make them up.

A thin cli wrapper has been built around the otter runner (which itself uses cli) in order to faciliate remote execution (by terraform) as well as local execution.

## Installation and running

### Dependencies

- [uv](https://docs.astral.sh/uv/) is the package manager POS. It is compatible
with PIP, so you can also fall back to it if you feel more comfortable.
- [terraform](https://developer.hashicorp.com/terraform) is the IaC tool by which the necessary infrastructure is assembled and destroyed.

## Configuration

All the configuration you need should be in the [config.yaml](config/config.yaml). Additional configuration for running specific commands (e.g. terraform config) can be given as command line options.

A folder for all the configuration is [here](config), which has the following:

- Main config for otter: [config.yaml](config/config.yaml) - Platform config.
- PPP specific config for otter: [config-ppp.yaml](config/config_ppp.yaml) - PPP specific config. When the commands have the `--product` option, `platform` will use [config.yaml](config/config.yaml) and `ppp` will use [config-ppp.yaml](config/config_ppp.yaml).
- Config for datasets, data sources/table names/settings etc. for Clickhouse, OpenSearch, BigQuery: [datasets.yaml](config/datasets.yaml)
- Clickhouse configs/schema/sql: [clickhouse](config/clickhouse/)
- OpenSearch Dockerfile/index settings: [opensearch](config/opensearch/)

## Commands

```bash
$ uv run pos --help                                                                                                   
Usage: pos [OPTIONS] COMMAND [ARGS]...

  Platform Output Support (POS) CLI

Options:
  --help  Show this message and exit.

Commands:
  local*              Run any POS step locally (default command).
  backend             Create platform backend using remote POS execution.
  bigquery            Populate BigQuery.
  clean-remote        Clean up remote POS resources after a remote run.
  ftp-sync            Release data to FTP.
  gcs-sync            Release data to GCS.
  remote              Run any POS step remotely on a machine defined by...
  restore-clickhouse  Restore ClickHouse from a backup.
  restore-opensearch  Restore OpenSearch from an OpenSearch snapshot.
  tarballs            Create platform tarballs using remote POS execution.
```
### `local` (default)

`local` is the default command so if you run without any command, this will invoke the otter cli:

```bash
$uv run pos       
Platform Output Support (POS) CLI
Usage: pos local [OPTIONS]

  Run any POS step locally (default command).

  Depending on the step and where you are running this, this may not work.

Options:
  -c, --config-path PATH          Path to configuration YAML file.
  -s, --step TEXT                 Step to run.  [required]
  -w, --work-path PATH            The local working path. This is where files
                                  will be downloaded and the manifest and logs
                                  will be written to.
  -r, --release-uri TEXT          If set, this URI will be used as the release
                                  location. This is where files will be
                                  uploaded and the manifest and logs will be
                                  written to.If omitted, the run will be local
                                  only.
  -p, --pool-size INTEGER         The number of worker proccesses that will be
                                  spawned to run tasksin the step in parallel.
                                  It should be similar to the number of
                                  cores,but could be higher because there is a
                                  lot of I/O blocking.
  -l, --log-level [TRACE|DEBUG|INFO|WARNING|ERROR|CRITICAL]
                                  Log level for the application.
  --help                          Show this message and exit.
```

### `backend`
Create the platform data backend artifacts. Note that this doesn't create tarballs nor does it _release_ any data. These are managed by other commands. Executes remotely.

```bash
$ uv run pos backend     
Platform Output Support (POS) CLI
Usage: pos backend [OPTIONS]

  Create platform backend using remote POS execution.

  Use this to creates the following resources: - Google Disk snapshots for
  ClickHouse and OpenSearch - OpenSearch snapshot in a remote GCS repository -
  ClickHouse backup in a remote GCS bucket

Options:
  --product [platform|ppp]  Product to create backend for.  [required]
  -p, --pool-size INTEGER   The number of worker proccesses that will be
                            spawned to run tasksin the step in parallel. It
                            should be similar to the number of cores,but could
                            be higher because there is a lot of I/O blocking.
  --pos-branch TEXT         The POS git branch to use for the remote run.
  --tfvar <TEXT TEXT>...    Terraform variable overrides as key-value pairs.
                            e.g., --tfvar key value
  --tfvar-file PATH         Path to a Terraform variable file.
  --auto-approve            Automatically approve Terraform actions without
                            prompting.
  --terraform-dir PATH      Path to the Terraform configuration directory.
  --help                    Show this message and exit.
  ```

e.g. `uv run pos backend --product platform` will create the backed for platform.

After this has been run, be sure to clean up the remote infrastructure with `clean-remote`.

### `bigquery`
e.g. `uv run pos bigquery --instance prod`
Use to release data to Google BigQuery (dev or prod). Executes locally.

### `clean-remote`
e.g. `uv run pos clean-remote`
Clean up any remote infrastucture created by Terraform. 

### `ftp-sync`
e.g. `uv run pos ftp-sync`
Release data to the ftp. Executes locally. From there, it connects to the EBI compute cluster and runs a `gcloud` container to sync data. 

### `gcs-sync`
e.g. `uv run pos gcs-sync --product platform`
Release data to Google Cloud Storage. Executes locally. 
Available for platform or ppp.

### `remote`
e.g. `uv run pos remote -s clickhouse`
Run any step in the config remotely.

### `tarballs`
e.g. `uv run pos tarballs --product platform --os-from-snapshot platform-2512-os --ch-from-snapshot platform-2512-ch`
Create the tarballs for clickhouse/opensearch data. 
Requires specifying the google disk snapshots that you wish to archive the data from. Executes remotely.

### `restore-clickhouse`
e.g. `uv run pos restore-clickhouse --product platform --target-instance production-clickhouse`
Restore the specified ClickHouse instance (gcp arguments can be passed as options) from the backup matching the database namespace in the config.

### `restore-opensearch`
e.g. `uv run pos restore-opensearch --product platform --target-instance production-opensearch`
Restore the specified OpenSearch instance (gcp arguments can be passed as options) from the backup matching the database namespace in the config.

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
