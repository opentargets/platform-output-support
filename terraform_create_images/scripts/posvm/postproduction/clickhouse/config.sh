#!/bin/bash

# Clickhouse postprocessing pipeline local configuration

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load global configuration
source ${SCRIPTDIR}/../config.sh

# Local configuration
# Clickhouse related postprocessing script paths
export pos_ch_path_config_root="${pos_path_postprocessing_scripts_clickhouse}/configuration"
export pos_ch_path_config="${pos_ch_path_config_root}/config.d"
export pos_ch_path_users="${pos_ch_path_config_root}/users.d"
# Database initialization schemas path
export pos_ch_path_schemas="${pos_path_postprocessing_scripts_clickhouse}/db_schemas"
# Database post-dataload scripts path
export pos_ch_path_sql_scripts_postdataload="${pos_path_postprocessing_scripts_clickhouse}/sql_scripts_postdataload"

# Clickhouse Storage Volume paths
# Path to the folder with clickhouse configuration files
export pos_ch_vol_path_clickhouse_config="${pos_mount_point_data_clickhouse}/config.d"
# Path to the folder with clickhouse users configuration files
export pos_ch_vol_path_clickhouse_users="${pos_mount_point_data_clickhouse}/users.d"
# Path to the folder with clickhouse data files
export pos_ch_vol_path_clickhouse_data="${pos_mount_point_data_clickhouse}/data"
# Clickhouse path for SQL scripts used after data load
export pos_ch_vol_path_sql_scripts_postdataload="/sql_scripts_postdataload"

# Clickhouse runtime configuration
export pos_ch_docker_container_name="otp-ch"
export pos_ch_docker_image="${pos_clickhouse_docker_image}:${pos_clickhouse_docker_image_version}"

# Data loading configuration, data sources and destination tables
declare -A pos_ch_data_release_sources=(
    ["ot.associations_otf_log"]="AOTFClickhouse/part*" \
    ["ot.literature_log"]="literature/literatureIndex/part*" \
    ["ot.ml_w2v_log"]="literature/vectors/part*" \
    ["ot.sentences_log"]="literature/literatureSentences/part*" \
)

# Print summary of the environment by looping through all those variables that start with "pos_ch_"
function env_summary() {
    echo "[CLICKHOUSE] Postprocessing pipeline environment summary:"
    for var in "${!pos_ch_@}"; do
        var_declaration=$(declare -p $var 2>/dev/null)
        if [[ $var_declaration == *"declare -A"* ]]; then
            # The variable is an associative array
            local -n array_reference=${var}
	    for key in "${!array_reference[@]}"; do
                echo "    ${var}[$key]=${array_reference[$key]}"
            done
        else
            # The variable is a primitive variable
            echo "    $var=${!var}"
        fi
    done
}



# Main
env_summary