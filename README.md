# POS — Open Targets Pipeline Output Stage

Create Platform backend (OpenSearch and Clickhouse) and release data.


## Summary

This application uses the [Otter](http://github.com/opentargets/otter) library to
define the steps of the pipeline that create and push all the output artifacts for a run of the Open Targets pipeline.

Check out the [config.yaml](config/config.yaml) file to see the steps and the tasks that
make them up.

TODO:
- [X] croissant
- [X] prep data for loading
- [X] load Clickhouse
- [X] load OpenSearch
- [X] create google disk snapshots for ch and os
- [X] create data tarballs
- [X] load BigQuery 
- [ ] GCS release
- [ ] FTP release

## Installation and running

POS uses [UV](https://docs.astral.sh/uv/) as its package manager. It is compatible
with PIP, so you can also fall back to it if you feel more comfortable.


```bash
uv run pos -h
```

### Configuration

A folder for all the configuration is [here](config), which has the following:

- Main config for otter: [config.yaml](config/config.yaml)
- Config for datasets, data sources/table names/settings etc. for Clickhouse, OpenSearch, BigQuery: [datasets.yaml](config/datasets.yaml)
- Clickhouse configs/schema/sql: [clickhouse](config/clickhouse/)
- OpenSearch Dockerfile/index settings: [opensearch](config/opensearch/)

It's configured by default to load all the necessary datasets, but it can be modified. Make sure that the dataset names in the config.yaml have a corresponding entry in the datasets.yaml and so on.

### Create the OT Platform backend
1. start a google vm and clone this repo, see installation.
   1. ideally something like n2-highmem-96 - reserve half the mem for the JVM
   2. external disk for opensearch
   3. external disk for clickhouse
2. opensearch (each step needs to be completed before starting the next)
   1. `uv run pos -p 300 -c config/config.yaml -s opensearch_prep_all`
   2. `uv run pos -p 100 -c config/config.yaml -s opensearch_load_all`
   3. `uv run pos -c config/config.yaml -s opensearch_stop`
   4. `uv run pos -c config/config.yaml -s opensearch_disk_snapshot`
   5. `uv run pos -c config/config.yaml -s opensearch_tarball`
3. clickhouse (each step needs to be completed before starting the next)
   1. `uv run pos -c config/config.yaml -s clickhouse_load_all`
   2. `uv run pos -c config/config.yaml -s clickhouse_stop`
   3. `uv run pos -c config/config.yaml -s clickhouse_disk_snapshot`
   4. `uv run pos -c config/config.yaml -s clickhouse_tarball`



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