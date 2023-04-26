#!/bin/bash
# Common configuration for all scripts, including a common toolset

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Environment variables
gcp_device_disk_clickhouse="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_CH}"
gcp_device_disk_elasticsearch="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_ES}"
# Data mount points
mount_point_data_clickhouse="${PATH_MOUNT_DATA_CLICKHOUSE}"
mount_point_data_elasticsearch="${PATH_MOUNT_DATA_ELASTICSEARCH}"
# Log folders
path_logs_postprocessing="${PATH_POSTPROCESSING_ROOT}/logs"
path_logs_clickhouse="$${path_logs_postprocessing}/clickhouse"
path_logs_elastic_search="$${path_logs_postprocessing}/elasticsearch"
# List of folders that need to exist for the postprocessing scripts to run
list_folders_postprocessing="$${path_logs_postprocessing} $${path_logs_clickhouse} $${path_logs_elastic_search}"

# Helper functions
# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

# Print a summary with the running environment
function env_summary() {
    log "(COMMON) Environment summary:"
    log "  - gcp_device_disk_clickhouse: $${gcp_device_disk_clickhouse}"
    log "  - gcp_device_disk_elasticsearch: $${gcp_device_disk_elasticsearch}"
    log "  - mount_point_data_clickhouse: $${mount_point_data_clickhouse}"
    log "  - mount_point_data_elasticsearch: $${mount_point_data_elasticsearch}"
    log "  - path_logs_postprocessing: $${path_logs_postprocessing}"
    log "  - path_logs_clickhouse: $${path_logs_clickhouse}"
    log "  - path_logs_elastic_search: $${path_logs_elastic_search}"
    log "  - list_folders_postprocessing: $${list_folders_postprocessing}"
    log "  - PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE: ${PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}"
    log "  - PATH_POSTPROCESSING_SCRIPTS_ELASTIC_SEARCH: ${PATH_POSTPROCESSING_SCRIPTS_ELASTIC_SEARCH}"
    log "  - PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_CLICKHOUSE: ${PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_CLICKHOUSE}"
    log "  - PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_ELASTIC_SEARCH: ${PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_ELASTIC_SEARCH}"
    log "  - DATA_RELEASE_SEKELETON_PATH_OUTPUT_ROOT: ${DATA_RELEASE_SEKELETON_PATH_OUTPUT_ROOT}"
    log "  - DATA_RELEASE_SEKELETON_PATH_ETL_ROOT: ${DATA_RELEASE_SEKELETON_PATH_ETL_ROOT}"
    log "  - DATA_RELEASE_SEKELETON_PATH_ETL_JSON_ROOT: ${DATA_RELEASE_SEKELETON_PATH_ETL_JSON_ROOT}"
    log "  - DATA_RELEASE_SEKELETON_PATH_ETL_PARQUET_ROOT: ${DATA_RELEASE_SEKELETON_PATH_ETL_PARQUET_ROOT}"
    log "  - DATA_RELEASE_PATH_SOURCE_ROOT: ${DATA_RELEASE_PATH_SOURCE_ROOT}"
    log "  - DATA_RELEASE_PATH_ETL_JSON: ${DATA_RELEASE_PATH_ETL_JSON}"
    log "  - DATA_RELEASE_PATH_ETL_PARQUET: ${DATA_RELEASE_PATH_ETL_PARQUET}"
    log "  - CLICKHOUSE_DOCKER_IMAGE: ${CLICKHOUSE_DOCKER_IMAGE}"
    log "  - CLICKHOUSE_DOCKER_IMAGE_VERSION: ${CLICKHOUSE_DOCKER_IMAGE_VERSION}"
}

# Function to format and mount a given disk device
function mount_disk() {
  local device_name=$1
  local mount_point=$2
  # Format the disk using ext4 with no reserved blocks
  log "Formatting disk $${device_name} with ext4"
  mkfs.ext4 -m 0 $${device_name}
  # Mount the disk
  log "Mounting disk $${device_name} to $${mount_point}"
  mkdir -p $${mount_point}
  mount -o defaults $${device_name} $${mount_point}
}

# Ensure that the list of folders that need to exist for the postprocessing scripts to run exist
function ensure_folders_exist() {
  for folder in $${list_folders_postprocessing}; do
    if [[ ! -d $${folder} ]]; then
      log "Creating folder $${folder}"
      mkdir -p $${folder}
    fi
  done
}

# Commong environment summary
env_summary