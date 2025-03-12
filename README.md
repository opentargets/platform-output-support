# POS — Open Targets Pipeline Output Stage

Create Platform backend (OpenSearch and Clickhouse) and release data.


## Summary

This application uses the [Otter](http://github.com/opentargets/otter) library to
define the steps of the pipeline that consume the output from the data generation pipeline 
and create the backend for the Open Targets Platform. There are also steps for releasing 
data via GCS, FTP and BigQuery.

Check out the [config.yaml](config/config.yaml) file to see the steps and the tasks that
make them up.


## Installation and running

POS uses [UV](https://docs.astral.sh/uv/) as its package manager. It is compatible
with PIP, so you can also fall back to it if you feel more comfortable.


```bash
uv run pos -h
```


## Development

> [!TIP]
> Take a look at the [Otter docs](https://opentargets.github.io/otter), it is a
> very helpful guide when developing new tasks.

You can test the changes by running a small step, like `so`:

```bash
uv run pos -c config/config.yaml --step data_prep
```


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