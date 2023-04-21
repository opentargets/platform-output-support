#!/bin/bash
# Common configuration for all scripts, including a common toolset

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Environment variables
gcp_device_disk_clickhouse="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_CH}"
gcp_device_disk_elasticsearch="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_ES}"
mount_point_data_clickhouse="${PATH_MOUNT_DATA_CLICKHOUSE}"
mount_point_data_elasticsearch="${PATH_MOUNT_DATA_ELASTICSEARCH}"

# Helper functions
# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
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

