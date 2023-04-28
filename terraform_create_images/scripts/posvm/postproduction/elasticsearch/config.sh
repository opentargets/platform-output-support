#!/bin/bash

# Elastic Search postprocessing pipeline local configuration

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load global configuration
source ${SCRIPTDIR}/../config.sh

# Local configuration
# Elastic Search volume paths
# Path to the folder with Elastic Search data files
export pos_es_vol_path_data="${pos_mount_point_data_elasticsearch}/data"