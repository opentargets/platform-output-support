#!/bin/bash

# This script launches the postprocessing pipeline tasks related to Clickhouse

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Local configuration
source ${SCRIPTDIR}/config.sh

# DEBUG - exit here
exit 0




# Helper functions
# Prepare Clickhouse Storage Volume
function prepare_clickhouse_storage_volume() {
  log "[START] Preparing Clickhouse Storage Volume"
  # Create Clickhouse Storage Volume folders
  mkdir -p ${ch_vol_path_clickhouse_config}
  mkdir -p ${ch_vol_path_clickhouse_users}
  mkdir -p ${ch_vol_path_clickhouse_data}
  # Copy Clickhouse configuration files
  cp ${pos_ch_path_config}/* ${ch_vol_path_clickhouse_config}
  # Copy Clickhouse users configuration files
  cp ${pos_ch_path_users}/* ${ch_vol_path_clickhouse_users}
  log "[DONE] Preparing Clickhouse Storage Volume"
}

# Run clickhouse via Docker 
function run_clickhouse() {
  log "[START] Running clickhouse via Docker, using image ${CLICKHOUSE_DOCKER_IMAGE}:${CLICKHOUSE_DOCKER_IMAGE_VERSION}"
  docker run --rm -d \
    --name ${ch_docker_container_name} \
    -p 9000:9000 \
    -p 8123:8123 \
    -v ${ch_vol_path_clickhouse_config}:/etc/clickhouse-server/config.d \
    -v ${ch_vol_path_clickhouse_users}:/etc/clickhouse-server/users.d \
    -v ${ch_vol_path_clickhouse_data}:/var/lib/clickhouse \
    -v ${path_logs_clickhouse}:/var/log/clickhouse-server \
    -v ${pos_ch_path_schemas}:/docker-entrypoint-initdb.d \
    -v ${pos_ch_path_sql_scripts_postdataload}:${ch_path_sql_scripts_postdataload} \
    --ulimit nofile=262144:262144 \
    ${ch_docker_image}
}

# Wait for Clickhouse to be ready
function wait_for_clickhouse() {
  log "[INFO] Waiting for Clickhouse to be ready"
  while ! docker exec ${ch_docker_container_name} clickhouse-client --query "SELECT 1" &> /dev/null; do
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
  log "[INFO] Loading release data from '${DATA_RELEASE_PATH_SOURCE_ROOT}' into Clickhouse"
  for table in "$(!ch_data_release_sources[@])"; do
    export path_source="${DATA_RELEASE_PATH_ETL_JSON}/${ch_data_release_sources[$table]}"
    log "[INFO] Loading release data from '${path_source}' into Clickhouse table '${table}'"
    gsutil -m cat ${path_source} | docker exec -i ${ch_docker_container_name} clickhouse-client --query="insert into ${table} format JSONEachRow "
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