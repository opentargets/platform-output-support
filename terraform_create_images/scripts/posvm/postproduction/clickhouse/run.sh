#!/bin/bash

# This script launches the postprocessing pipeline tasks related to Clickhouse

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Local configuration
source ${SCRIPTDIR}/config.sh

# Helper functions
# Prepare Clickhouse Storage Volume
function prepare_clickhouse_storage_volume() {
  log "[START] Preparing Clickhouse Storage Volume"
  # Create Clickhouse Storage Volume folders
  mkdir -p ${pos_ch_vol_path_clickhouse_config}
  mkdir -p ${pos_ch_vol_path_clickhouse_users}
  mkdir -p ${pos_ch_vol_path_clickhouse_data}
  # Copy Clickhouse configuration files
  cp ${pos_ch_path_config}/* ${pos_ch_vol_path_clickhouse_config}
  # Copy Clickhouse users configuration files
  cp ${pos_ch_path_users}/* ${pos_ch_vol_path_clickhouse_users}
  log "[DONE] Preparing Clickhouse Storage Volume"
}

# Run clickhouse via Docker 
function run_clickhouse() {
  log "[START] Running clickhouse via Docker, using image ${pos_ch_docker_image}"
  docker run --rm -d \
    --name ${pos_ch_docker_container_name} \
    -p 9000:9000 \
    -p 8123:8123 \
    -v ${pos_ch_vol_path_clickhouse_config}:/etc/clickhouse-server/config.d \
    -v ${pos_ch_vol_path_clickhouse_users}:/etc/clickhouse-server/users.d \
    -v ${pos_ch_vol_path_clickhouse_data}:/var/lib/clickhouse \
    -v ${pos_path_logs_clickhouse}:/var/log/clickhouse-server \
    -v ${pos_ch_path_schemas}:/docker-entrypoint-initdb.d \
    -v ${pos_ch_path_sql_scripts_postdataload}:${pos_ch_vol_path_sql_scripts_postdataload} \
    --ulimit nofile=262144:262144 \
    ${pos_ch_docker_image}
}

# Wait for Clickhouse to be ready
function wait_for_clickhouse() {
  log "[INFO] Waiting for Clickhouse to be ready"
  while ! docker exec ${pos_ch_docker_container_name} clickhouse-client --query "SELECT 1" &> /dev/null; do
    sleep 1
  done
  log "[INFO] Clickhouse is ready"
}

# Load release data into Clickhouse
function load_release_data() {
  log "[START] Loading release data into Clickhouse"
  # Wait for Clickhouse to be ready
  wait_for_clickhouse
  # Load release data
  log "[INFO] Loading release data from '${pos_data_release_path_source_root}' into Clickhouse"
  for table in "${!pos_ch_data_release_sources[@]}"; do
    export path_source="${pos_data_release_path_etl_json}/${pos_ch_data_release_sources[$table]}"
    log "[INFO] Loading release data from '${path_source}' into Clickhouse table '${table}'"
    gsutil -m cat ${path_source} | docker exec -i ${pos_ch_docker_container_name} clickhouse-client --query="insert into ${table} format JSONEachRow "
  done
  log "[DONE] Loading release data into Clickhouse"
}




# Main
# Prepare Clickhouse Storage Volume
prepare_clickhouse_storage_volume
# Launch Clickhouse
run_clickhouse
# Load release data into Clickhouse
load_release_data