#!/bin/bash
# Startup script for Elastic Search VM Instance

# Environment variables
flag_startup_completed="/tmp/posvm_startup_complete"

# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

# This function updates the system and installs the required packages
function install_packages() {
  log "Updating system"
  apt-get update
  log "Installing required packages"
  apt-get install -y wget vim tmux python3-pip docker.io docker-compose tree htop
  log "Adding POS user '${POS_USER_NAME}' to docker group"
  usermod -aG docker ${POS_USER_NAME}
  log "Installing esbulk loader"
  wget https://github.com/miku/esbulk/releases/download/v0.7.3/esbulk_0.7.3_amd64.deb
  dpkg -i esbulk_0.7.3_amd64.deb
}

# Script completion hook to flag that 'startup script' has already been run
function startup_complete() {
  log "Startup script completed"
  touch $${flag_startup_completed}
}

# Environment summary function
function env_summary() {
  log "Environment summary:"
  log "  PROJECT_ID: ${PROJECT_ID}"
  log "  GC_ZONE: ${GC_ZONE}"
  log "  GS_ETL_DATASET: ${GS_ETL_DATASET}"
  log "  IS_PARTNER_INSTANCE: ${IS_PARTNER_INSTANCE}"
  log "  GS_DIRECT_FILES: ${GS_DIRECT_FILES}"
  log "  GCP_DEVICE_DISK_PREFIX: ${GCP_DEVICE_DISK_PREFIX}"
  log "  DATA_DISK_DEVICE_NAME_CH: ${DATA_DISK_DEVICE_NAME_CH}"
  log "  DATA_DISK_DEVICE_NAME_ES: ${DATA_DISK_DEVICE_NAME_ES}"
  log "  DISK_IMAGE_NAME_CH: ${DISK_IMAGE_NAME_CH}"
  log "  DISK_IMAGE_NAME_ES: ${DISK_IMAGE_NAME_ES}"
  log "  POS_REPO_BRANCH: ${POS_REPO_BRANCH}"
  log "  FLAG_POSTPROCESSING_SCRIPTS_READY: ${FLAG_POSTPROCESSING_SCRIPTS_READY}"
  log "  PATH_POSTPROCESSING_SCRIPTS: ${PATH_POSTPROCESSING_SCRIPTS}"
  log "  FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT: ${FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT}"
  log "  CLICKHOUSE_URI: ${CLICKHOUSE_URI}"
  log "  ELASTICSEARCH_URI: ${ELASTICSEARCH_URI}"
  log "  gcp_device_disk_clickhouse: $${gcp_device_disk_clickhouse}"
  log "  gcp_device_disk_elasticsearch: $${gcp_device_disk_elasticsearch}"
  log "  mount_point_clickhouse: $${mount_point_clickhouse}"
  log "  mount_point_elasticsearch: $${mount_point_elasticsearch}"
}

# Set trap to run 'startup_complete' function on exit
trap startup_complete EXIT

# Check if startup script has already been run
if [[ -f $${flag_startup_completed} ]]; then
  log "Startup script already completed, skipping"
  exit 0
fi

# Main Script
log "===> [BOOTSTRAP] POS support VM <==="
env_summary
install_packages
# Wait until the "ready" flag for postprocessing scripts is set, timeout after 20 minutes
log "Waiting for postprocessing scripts to be ready, timeout after 20 minutes"
timeout 1200 bash -c "until [[ -f ${FLAG_POSTPROCESSING_SCRIPTS_READY} ]]; do sleep 1; done"
# Change current dir to the postprocessing scripts dir
cd ${PATH_POSTPROCESSING_SCRIPTS}
# Launch the postprocessing scripts
log "Launching postprocessing scripts, at $$(pwd)"
./${FILENAME_POSTPROCESSING_SCRIPTS_ENTRY_POINT}
log "Postprocessing scripts completed"
# Shutting down this postproduction machine
log "[--- Shutting down this postproduction machine ---]"
#poweroff