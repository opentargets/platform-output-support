#!/bin/bash

# Clickhouse postprocessing pipeline local configuration

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load global configuration
source ${SCRIPTDIR}/../config.sh

# Local configuration
# Path to the folder with clickhouse configuration files
path_config_clickhouse="${mount_point_data_clickhouse}/config.d"
# Path to the folder with clickhouse users configuration files
path_config_clickhouse_users="${mount_point_data_clickhouse}/users.d"
# Path to the folder with clickhouse data files
path_data_clickhouse="${mount_point_data_clickhouse}/data"