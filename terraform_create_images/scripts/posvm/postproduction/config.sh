#!/bin/bash
# Common configuration for all scripts, including a common toolset

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Environment variables
# Remapping of values rendered by Terraform into environment variables (there must way another way to do this, that it is not so ugly)
export pos_project_id=${POS_PROJECT_ID}
export pos_gcp_zone=${POS_GCP_ZONE}
export pos_is_partner_instance=${POS_IS_PARTNER_INSTANCE}
export pos_gcp_device_disk_prefix=${POS_GCP_DEVICE_DISK_PREFIX}
export pos_data_disk_device_name_ch=${POS_DATA_DISK_DEVICE_NAME_CH}
export pos_data_disk_device_name_es=${POS_DATA_DISK_DEVICE_NAME_ES}
export pos_disk_image_name_ch=${POS_DISK_IMAGE_NAME_CH}
export pos_disk_image_family_ch="ot-ch"
export pos_disk_image_name_es=${POS_DISK_IMAGE_NAME_ES}
export pos_disk_image_family_es="ot-es7"
export pos_disk_image_labels_ch=${POS_DISK_IMAGE_LABELS_CH}
export pos_disk_image_labels_es=${POS_DISK_IMAGE_LABELS_ES}
export pos_path_mount_data_clickhouse=${POS_PATH_MOUNT_DATA_CLICKHOUSE}
export pos_path_mount_data_elasticsearch=${POS_PATH_MOUNT_DATA_ELASTICSEARCH}
export pos_path_postprocessing_scripts_clickhouse=${POS_PATH_POSTPROCESSING_SCRIPTS_CLICKHOUSE}
export pos_path_postprocessing_scripts_elastic_search=${POS_PATH_POSTPROCESSING_SCRIPTS_ELASTIC_SEARCH}
export pos_path_postprocessing_scripts_entry_point_clickhouse=${POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_CLICKHOUSE}
export pos_path_postprocessing_scripts_entry_point_elastic_search=${POS_PATH_POSTPROCESSING_SCRIPTS_ENTRY_POINT_ELASTIC_SEARCH}
export pos_data_release_sekeleton_path_output_root=${POS_DATA_RELEASE_SEKELETON_PATH_OUTPUT_ROOT}
export pos_data_release_sekeleton_path_input_root=${POS_DATA_RELEASE_SEKELETON_PATH_INPUT_ROOT}
export pos_data_release_sekeleton_path_etl_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_ROOT}
export pos_data_release_sekeleton_path_etl_json_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_JSON_ROOT}
export pos_data_release_sekeleton_path_etl_parquet_root=${POS_DATA_RELEASE_SEKELETON_PATH_ETL_PARQUET_ROOT}
export pos_data_release_sekeleton_path_metadata_root=${POS_DATA_RELEASE_SEKELETON_PATH_METADATA_ROOT}
export pos_data_release_path_source_root=${POS_DATA_RELEASE_PATH_SOURCE_ROOT}
export pos_data_release_path_etl_json=${POS_DATA_RELEASE_PATH_ETL_JSON}
export pos_data_release_path_etl_parquet=${POS_DATA_RELEASE_PATH_ETL_PARQUET}
export pos_data_release_path_input_root=${POS_DATA_RELEASE_PATH_INPUT_ROOT}
export pos_data_release_path_webapp_root="$${pos_data_release_path_source_root}/webapp"
export pos_data_release_path_metadata_root="$${pos_data_release_path_source_root}/$${pos_data_release_sekeleton_path_metadata_root}"
export pos_data_release_path_disk_images_root="$${pos_data_release_path_source_root}/disk_images"
export pos_data_disk_tarball_clickhouse="${POS_DATA_DISK_TARBALL_CLICKHOUSE}"
export pos_data_disk_tarball_elastic_search="${POS_DATA_DISK_TARBALL_ELASTIC_SEARCH}"
export pos_clickhouse_docker_image=${POS_CLICKHOUSE_DOCKER_IMAGE}
export pos_clickhouse_docker_image_version=${POS_CLICKHOUSE_DOCKER_IMAGE_VERSION}
export pos_elasticsearch_docker_image=${POS_ELASTIC_SEARCH_DOCKER_IMAGE}
export pos_elasticsearch_docker_image_version=${POS_ELASTIC_SEARCH_DOCKER_IMAGE_VERSION}
export pos_flag_postprocessing_scripts_ready=${POS_FLAG_POSTPROCESSING_SCRIPTS_READY}
export pos_gcp_path_pos_pipeline_session_logs=${POS_GCP_PATH_POS_PIPELINE_SESSION_LOGS}
export pos_path_postprocessing_root=${POS_PATH_POSTPROCESSING_ROOT}
export pos_path_postprocessing_scripts=${POS_PATH_POSTPROCESSING_SCRIPTS}
export pos_filename_postprocessing_scripts_entry_point=${POS_FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT}

# Newly defined
export pos_gcp_device_disk_clickhouse="${POS_GCP_DEVICE_DISK_PREFIX}${POS_DATA_DISK_DEVICE_NAME_CH}"
export pos_gcp_device_disk_elasticsearch="${POS_GCP_DEVICE_DISK_PREFIX}${POS_DATA_DISK_DEVICE_NAME_ES}"
export pos_webapp_source_diseases_efo="$${pos_data_release_path_input_root}/ontology-inputs/diseases_efo.jsonl"
export pos_webapp_destination_diseases_efo="$${pos_data_release_path_webapp_root}/ontology/efo_json/diseases_efo.jsonl"
export pos_webapp_destination_downloads_metadata="$${pos_data_release_path_webapp_root}/downloads.json"
# Data mount points
export pos_mount_point_data_clickhouse="${POS_PATH_MOUNT_DATA_CLICKHOUSE}"
export pos_mount_point_data_elasticsearch="${POS_PATH_MOUNT_DATA_ELASTICSEARCH}"
# Log folders
export pos_path_logs_postprocessing="${POS_PATH_POSTPROCESSING_ROOT}/logs"
export pos_path_logs_clickhouse="$${pos_path_logs_postprocessing}/clickhouse"
export pos_path_logs_elastic_search="$${pos_path_logs_postprocessing}/elasticsearch"
export pos_path_logs_pos="$${pos_path_logs_postprocessing}/pos"
export pos_path_logs_startup_script="$${pos_path_logs_pos}/startup_script.log"
# Temporary folders
export pos_path_tmp="${POS_PATH_POSTPROCESSING_ROOT}/tmp"
# List of folders that need to exist for the postprocessing scripts to run
export pos_list_folders_postprocessing="$${pos_path_logs_postprocessing} $${pos_path_logs_clickhouse} $${pos_path_logs_elastic_search} $${pos_path_logs_pos} $${pos_path_tmp}"

# Helper functions
# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

function logf() {
  log "$@" | tee -a $${pos_path_logs_startup_script}
}

# Print a summary with the running environment (all environment variables starting with POS_)
function env_summary() {
  log "[GLOBAL] Environment summary:"
  for var in $(compgen -e | grep pos_); do
    log "  - $${var} = $${!var}"
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
  for folder in $${pos_list_folders_postprocessing}; do
    if [[ ! -d $${folder} ]]; then
      log "Creating folder $${folder}"
      mkdir -p $${folder}
    fi
  done
}

# Common environment summary
env_summary
