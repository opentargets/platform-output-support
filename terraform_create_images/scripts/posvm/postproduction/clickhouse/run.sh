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
  mkdir -p ${pos_ch_vol_path_parquet}
  # Copy Clickhouse configuration files
  cp ${pos_ch_path_config}/* ${pos_ch_vol_path_clickhouse_config}
  # Copy Clickhouse users configuration files
  cp ${pos_ch_path_users}/* ${pos_ch_vol_path_clickhouse_users}
  log "[DONE] Preparing Clickhouse Storage Volume"
}

# Run clickhouse via Docker 
function run_clickhouse() {
  log "[START] Running clickhouse via Docker, using image ${pos_ch_docker_image}, container with name '${pos_ch_docker_container_name}'"
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
    sleep 3
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
    export path_source="${pos_data_release_path_etl_parquet}/${pos_ch_data_release_sources[$table]}"
    success=0
    # Attempts for the current table
    for attempt in {1..12}; do
      log "[INFO] (Attempt ${attempt}) ${path_source}' -> '${table}'"
      gsutil -m rsync -r -d ${path_source} "${pos_ch_vol_path_parquet}/"
      shopt -s globstar
      pq_failed=0
      for pq in ${pos_ch_vol_path_parquet}/**/*.parquet; do
        insert_query="insert into ${table} format Parquet"
        if docker exec -i ${pos_ch_docker_container_name} clickhouse-client --query="${insert_query}" < $pq ; then
          log "[INFO] Loaded '${pq}' into Clickhouse table '${table}'"
        else
          log "[ERROR] Failed to load '${pq}' into Clickhouse table '${table}'"
          pq_failed=1
          docker exec -i ${pos_ch_docker_container_name} clickhouse-client --query="TRUNCATE TABLE ${table}" 
        fi
        rm -f $pq
      done
      if [ $pq_failed -eq 0 ]; then
        success=1
        break
      fi
    done
    if [ $success -eq 1 ]; then
      log "[SUCCESS] Data loaded into Clickhouse table '${table}' after ${attempt} attempts"
    else
      log "[ERROR] Failed to load data into Clickhouse table '${table}' after 7 attempts"
    fi
  done
  # Run post data load scripts located at ${pos_ch_path_sql_scripts_postdataload}
  for sql_file in $( ls ${pos_ch_path_sql_scripts_postdataload}/*.sql ); do
    log "[INFO] Running post data load script '${sql_file}'"
    cat ${sql_file} | docker exec -i ${pos_ch_docker_container_name} clickhouse-client --multiline --multiquery
  done
  log "[DONE] Loading release data into Clickhouse"
}

# Show a summary of the Clickhouse data loaded
function show_clickhouse_data_summary() {
  log "[INFO] Showing a summary of the Clickhouse data loaded"
  local CHCLIENT="docker exec ${pos_ch_docker_container_name} clickhouse-client"
  for table in $( ${CHCLIENT} -q "show tables in ot" ) ; do
    local fqdn=ot.$table
    local table_count=$( ${CHCLIENT} -q "select count() from $fqdn" )
    log " Count for '$fqdn' ---> $table_count"
  done
  log "[DONE] Showing a summary of the Clickhouse data loaded"
}

# Stop the running Clickhouse container
function stop_clickhouse() {
  log "[START] Stopping Clickhouse, container name: ${pos_ch_docker_container_name}"
  docker stop ${pos_ch_docker_container_name}
  log "[DONE] Stopping Clickhouse, container name: ${pos_ch_docker_container_name}"
}




# Main
# Prepare Clickhouse Storage Volume
prepare_clickhouse_storage_volume
# Launch Clickhouse
run_clickhouse
# Load release data into Clickhouse
load_release_data
# Show a summary of the Clickhouse data loaded
show_clickhouse_data_summary
# Stop Clickhouse
stop_clickhouse
