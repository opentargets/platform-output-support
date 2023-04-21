#!/bin/bash
# This script launches the postprocessing pipeline

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Create a temporary folder for the script
TMPDIR=$(mktemp -d)

# Load common configuration script
source ${SCRIPTDIR}/config.sh










# Main
log "Mount data disks for Clickhouse and Elastic Search"
mount_disk $${gcp_device_disk_clickhouse} $${mount_point_data_clickhouse}
mount_disk $${gcp_device_disk_elasticsearch} $${mount_point_data_elasticsearch}
log "Make sure the list of folders needed to operate the postprocessing pipeline exist"
ensure_folders_exist