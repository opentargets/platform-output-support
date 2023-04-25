#!/bin/bash

# Clickhouse postprocessing pipeline local configuration

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load global configuration
source ${SCRIPTDIR}/../config.sh

# Local configuration
# Clickhouse related postprocessing script paths
pos_ch_path_config="${PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}/config.d"
pos_ch_path_users="${PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}/users.d"
# Clickhouse Storage Volume paths
# Path to the folder with clickhouse configuration files
ch_vol_path_clickhouse_config="${mount_point_data_clickhouse}/config.d"
# Path to the folder with clickhouse users configuration files
ch_vol_path_clickhouse_users="${mount_point_data_clickhouse}/users.d"
# Path to the folder with clickhouse data files
ch_vol_path_clickhouse_data="${mount_point_data_clickhouse}/data"