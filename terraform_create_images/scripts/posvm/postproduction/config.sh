#!/bin/bash
# Common configuration for all scripts, including a common toolset

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Environment variables
# Remapping of values rendered by Terraform into environment variables (there must way another way to do this, that it is not so ugly)
pos_project_id=${POS_PROJECT_ID}
pos_gc_zone=${POS_GC_ZONE}
pos_gs_etl_dataset=${POS_GS_ETL_DATASET}
pos_is_partner_instance=${POS_IS_PARTNER_INSTANCE}
pos_gs_direct_files=${POS_GS_DIRECT_FILES}
pos_gcp_device_disk_prefix=${POS_GCP_DEVICE_DISK_PREFIX}
pos_data_disk_device_name_ch=${POS_DATA_DISK_DEVICE_NAME_CH}
pos_data_disk_device_name_es=${POS_DATA_DISK_DEVICE_NAME_ES}
pos_disk_image_name_ch=${POS_DISK_IMAGE_NAME_CH}
pos_disk_image_name_es=${POS_DISK_IMAGE_NAME_ES}
pos_path_mount_data_clickhouse=${POS_PATH_MOUNT_DATA_CLICKHOUSE}
pos_path_mount_data_elasticsearch=${POS_PATH_MOUNT_DATA_ELASTICSEARCH}
pos_path_postprocessing_scripts_clickhouse=${POS_PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}
pos_path_postprocessing_scripts_elastic_search=${POS_PATH_POSTPROCESSING_SCRIPTS_ELASTIC_SEARCH}
pos_path_postprocessing_scripts_entry_point_clickhouse=${POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_CLICKHOUSE}
pos_path_postprocessing_scripts_entry_point_elastic_search=${POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_ELASTIC_SEARCH}
pos_data_release_sekeleton_path_output_root=${POS_DATA_RELEASE_SEKELETON_PATH_OUTPUT_ROOT}
pos_data_release_sekeleton_path_etl_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_ROOT}
pos_data_release_sekeleton_path_etl_json_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_JSON_ROOT}
pos_data_release_sekeleton_path_etl_parquet_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_PARQUET_ROOT}
pos_data_release_path_source_root=${POS_DATA_RELEASE_PATH_SOURCE_ROOT}
pos_data_release_path_etl_json=${POS_DATA_RELEASE_PATH_ETL_JSON}
pos_data_release_path_etl_parquet=${POS_DATA_RELEASE_PATH_ETL_PARQUET}
pos_clickhouse_docker_image=${POS_CLICKHOUSE_DOCKER_IMAGE}
pos_clickhouse_docker_image_version=${POS_CLICKHOUSE_DOCKER_IMAGE_VERSION}
pos_pos_repo_branch=${POS_POS_REPO_BRANCH}
pos_flag_postprocessing_scripts_ready=${POS_FLAG_POSTPROCESSING_SCRIPTS_READY}
pos_path_postprocessing_root=${POS_PATH_POSTPROCESSING_ROOT}
pos_path_postprocessing_scripts=${POS_PATH_POSTPROCESSING_SCRIPTS}
pos_filename_postprocessing_scripts_entry_point=${POS_FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT}
pos_clickhouse_uri=${POS_CLICKHOUSE_URI}
pos_elasticsearch_uri=${POS_ELASTICSEARCH_URI}
pos_image_prefix=${POS_IMAGE_PREFIX}

# Newly defined
pos_gcp_device_disk_clickhouse="${POS_GCP_DEVICE_DISK_PREFIX}${POS_DATA_DISK_DEVICE_NAME_CH}"
pos_gcp_device_disk_elasticsearch="${POS_GCP_DEVICE_DISK_PREFIX}${POS_DATA_DISK_DEVICE_NAME_ES}"
# Data mount points
pos_mount_point_data_clickhouse="${POS_PATH_MOUNT_DATA_CLICKHOUSE}"
pos_mount_point_data_elasticsearch="${POS_PATH_MOUNT_DATA_ELASTICSEARCH}"
# Log folders
pos_path_logs_postprocessing="${POS_PATH_POSTPROCESSING_ROOT}/logs"
pos_path_logs_clickhouse="$${pos_path_logs_postprocessing}/clickhouse"
pos_path_logs_elastic_search="$${pos_path_logs_postprocessing}/elasticsearch"
# List of folders that need to exist for the postprocessing scripts to run
pos_list_folders_postprocessing="$${pos_path_logs_postprocessing} $${pos_path_logs_clickhouse} $${pos_path_logs_elastic_search}"

# Helper functions
# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

# Print a summary with the running environment (all environment variables starting with POS_)
function env_summary() {
  log "[GLOBAL] Environment summary:"
  for var in $(env | grep pos_); do
    log "  - $${!var} = $${var}"
  done
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