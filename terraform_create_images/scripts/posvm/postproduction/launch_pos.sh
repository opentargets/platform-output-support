#!/bin/bash
# This script launches the postprocessing pipeline

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Create a temporary folder for the script
TMPDIR=$(mktemp -d)

# Load common configuration script
source ${SCRIPTDIR}/config.sh


# --- Main ---
log "Mount data disks for Clickhouse and Elastic Search"
mount_disk ${pos_gcp_device_disk_clickhouse} ${pos_mount_point_data_clickhouse}
mount_disk ${pos_gcp_device_disk_elasticsearch} ${pos_mount_point_data_elasticsearch}
log "Make sure the list of folders needed to operate the postprocessing pipeline exist"
ensure_folders_exist
# Run Clickhouse data load in the background and wait for it to finish
log "[--- Run Clickhouse data pipeline ---]"
log "[DEBUG] --- SKIP RUNNING CLICKHOUSE DATA PIPELINE ---"
#cd $( dirname ${pos_path_postprocessing_scripts_entry_point_clickhouse}) ; ./$(basename ${pos_path_postprocessing_scripts_entry_point_clickhouse})
# TODO - Detach Clickhouse storage volume
# TODO - Create Clickhouse storage volume image

# Run Elastic Search data loading process
log "[--- Run Elastic Search data pipeline ---]"
cd $( dirname ${pos_path_postprocessing_scripts_entry_point_elastic_search}) ; ./$(basename ${pos_path_postprocessing_scripts_entry_point_elastic_search})