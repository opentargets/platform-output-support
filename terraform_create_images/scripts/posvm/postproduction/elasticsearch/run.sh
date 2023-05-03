#!/bin/bash

# This script starts the postprocessing pipeline for loading data into Elastic Search

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load local configuration
source ${SCRIPTDIR}/config.sh

# Helper functions
# Prepare Elastic Search Storage Volume
function prepare_elasticsearch_storage_volume() {
  log "[START] Preparing Elastic Search Storage Volume"
  # Create Elastic Search Storage Volume folders
  mkdir -p ${pos_es_vol_path_data}
  log "[DONE] Preparing Elastic Search Storage Volume"
}

# Run Elastic Search via Docker
function run_elasticsearch() {
  log "[START] Running Elastic Search via Docker, using image ${pos_es_docker_image}"
  local pos_es_cluster_name=`hostname`
  docker run --rm -d \
    --name ${pos_es_docker_container_name} \
    -p 9200:9200 \
    -p 9300:9300 \
    -e ES_SETTING_PATH_DATA=/usr/share/elasticsearch/data \
    -e ES_SETTING_PATH_LOGS=/usr/share/elasticsearch/logs \
    -e ES_SETTING_CLUSTER_NAME=${pos_es_cluster_name} \
    -e ES_SETTING_NETWORK_HOST=0.0.0.0 \
    -e ES_SETTING_DISCOVERY_TYPE=single-node \
    -e ES_SETTING_BOOTSTRAP_MEMORY__LOCK=true \
    -e ES_SETTING_SEARCH_MAX__OPEN__SCROLL__CONTEXT=5000 \
    -v ${pos_es_vol_path_data}:/usr/share/elasticsearch/data \
    -v ${pos_path_logs_elastic_search}:/usr/share/elasticsearch/logs \
    --ulimit memlock=-1:-1 \
    --ulimit nofile=65536:65536 \
    ${pos_es_docker_image}
}

# Wait for Elastic Search to be ready
function wait_for_elasticsearch() {
  log "[INFO] Waiting for Elastic Search to be ready"
  while ! curl -s http://localhost:9200/_cluster/health?pretty | grep -q '"status" : "green"'; do
    sleep 1
  done
  log "[INFO] Elastic Search is ready"
}

# Load data into Elastic Search for a given input_folder, index_name, id and index_settings
function load_data_into_es_index() {
  local input_folder=$1
  local index_name=$2
  local id=$3
  local index_settings=$4
  local path_to_index_settings="${pos_es_path_index_settings}/${index_settings}"
  local path_to_input_folder="${pos_data_release_path_etl_json}/${input_folder}"
  log "[START][${index_name}] Loading data into Elastic Search for input_folder=${input_folder}, index_name=${index_name}, id=${id}, index_settings=${index_settings}"
  # Create index
  log "[INFO][${index_name}] Creating index"
  curl -X PUT "localhost:9200/${index_name}?pretty" -H 'Content-Type: application/json' -d"${path_to_index_settings}"
  log "[INFO][${index_name}] Data source at '${path_to_input_folder}'"
  # Iterate over all .json files in the input folder and load them into the created index
  for file in $(gsutil list ${path_to_input_folder}/*.json); do
    if [[ -n "$id" ]]; then
      log "[INFO][${index_name}] Loading data file '${file}' with id '${id}'"
      #gsutil cp ${file} - | esbulk -size 2000 -w 8 -index ${index_name} -type _doc -server http://localhost:9200 -id ${id} 
    else
      log "[INFO][${index_name}] Loading data file '${file}' without id"
      #gsutil cp ${file} - | esbulk -size 2000 -w 8 -index ${index_name} -type _doc -server http://localhost:9200
    fi
  done
  log "[DONE][${index_name}] Loading data into Elastic Search for input_folder=${input_folder}, index_name=${index_name}, id=${id}, index_settings=${index_settings}"
}

# TODO - Load Evidence data into Elastic Search

# Iterate over the ETL ingestion configuration file and load data into Elastic Search
function load_etl_data_into_es() {
  while IFS= read -r line
  do
      # Skip lines starting with '#'
      if [[ $line =~ ^# ]]; then
          continue
      fi

      # Process the line as CSV
      IFS=, read -r input_folder index_name id index_settings <<< "$line"
      load_data_into_es_index ${input_folder} ${index_name} ${id} ${index_settings}
  done < "${pos_es_path_etl_ingestion_config}"
}


# Main
# Prepare Elastic Search Storage Volume
prepare_elasticsearch_storage_volume
# Run Elastic Search via Docker
run_elasticsearch
# Wait for Elastic Search to be ready
wait_for_elasticsearch
# Load data into Elastic Search
load_etl_data_into_es