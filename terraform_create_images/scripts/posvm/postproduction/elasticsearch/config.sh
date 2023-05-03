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
# Path to the folder with Elastic Search metadata files
export pos_es_path_metadata="${pos_path_postprocessing_scripts_elastic_search}/metadata"
# Path to folder with Elastic Search index settings files
export pos_es_path_index_settings="${pos_path_postprocessing_scripts_elastic_search}/index_settings"
# Path to ETL ingestion configuration file
export pos_es_path_etl_ingestion_config="${pos_es_path_metadata}/etl_ingest_configuration.csv"

# Elastic Search runtime configuration
export pos_es_docker_container_name="otp-es"
export pos_es_docker_image="${pos_elasticsearch_docker_image}:${pos_elasticsearch_docker_image_version}"

# Print summary of the environment by looping through all those variables that start with "pos_es_"
function env_summary() {
    echo "[ELASTICSEARCH] Postprocessing pipeline environment summary:"
    for var in "${!pos_es_@}"; do
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