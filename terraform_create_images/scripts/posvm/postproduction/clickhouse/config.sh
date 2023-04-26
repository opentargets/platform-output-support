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
# Database initialization schemas path
pos_ch_path_schemas="${PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}/db_schemas"
# Database post-dataload scripts path
pos_ch_path_sql_scripts_postdataload="${PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}/sql_scripts_postdataload"

# Clickhouse Storage Volume paths
# Path to the folder with clickhouse configuration files
ch_vol_path_clickhouse_config="${mount_point_data_clickhouse}/config.d"
# Path to the folder with clickhouse users configuration files
ch_vol_path_clickhouse_users="${mount_point_data_clickhouse}/users.d"
# Path to the folder with clickhouse data files
ch_vol_path_clickhouse_data="${mount_point_data_clickhouse}/data"
# Clickhouse path for SQL scripts used after data load
ch_path_sql_scripts_postdataload="/sql_scripts_postdataload"

# Clickhouse runtime configuration
ch_docker_container_name="otp-ch"
ch_docker_image="${CLICKHOUSE_DOCKER_IMAGE}:${CLICKHOUSE_DOCKER_IMAGE_VERSION}"

# Data loading configuration, data sources and destination tables
ch_data_release_sources=(
    ["ot.associations_otf_log"]="AOTFClickhouse/part*"
    ["ot.literature_log"]="literature/literatureIndex/part*"
    ["ot.ml_w2v_log"]="literature/vectors/part*"
    ["ot.sentences_log"]="literature/literatureSentences/part*"
)

# Local environment summary
function env_summary() {
    log "[INFO] Clickhouse postprocessing pipeline (LOCAL) configuration:"
    log "[INFO] Clickhouse related postprocessing script paths:"
    log "[INFO] pos_ch_path_config=${pos_ch_path_config}"
    log "[INFO] pos_ch_path_users=${pos_ch_path_users}"
    log "[INFO] pos_ch_path_schemas=${pos_ch_path_schemas}"
    log "[INFO] pos_ch_path_sql_scripts_postdataload=${pos_ch_path_sql_scripts_postdataload}"
    log "[INFO] Clickhouse Storage Volume paths:"
    log "[INFO] ch_vol_path_clickhouse_config=${ch_vol_path_clickhouse_config}"
    log "[INFO] ch_vol_path_clickhouse_users=${ch_vol_path_clickhouse_users}"
    log "[INFO] ch_vol_path_clickhouse_data=${ch_vol_path_clickhouse_data}"
    log "[INFO] ch_docker_container_name=${ch_docker_container_name}"
    log "[INFO] ch_docker_image=${ch_docker_image}"
    log "[INFO] Data loading configuration, data sources and destination tables:"
    log "[INFO] ch_data_release_sources=${ch_data_release_sources[@]}"
}

# Main
env_summary