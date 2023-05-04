#!/bin/bash
# This script launches the postprocessing pipeline

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Create a temporary folder for the script
TMPDIR=$(mktemp -d)

# Load common configuration script
source ${SCRIPTDIR}/config.sh

# Helper functions
function mount_data_volumes() {
    log "Mount data disks for Clickhouse and Elastic Search"
    mount_disk ${pos_gcp_device_disk_clickhouse} ${pos_mount_point_data_clickhouse}
    mount_disk ${pos_gcp_device_disk_elasticsearch} ${pos_mount_point_data_elasticsearch}
}

# Prepare the web application static data context
function prepare_webapp_static_data_context() {
    log "[START] Preparing web application static data context"
    log "[INFO] Copying web application static data from '${pos_webapp_source_diseases_efo}' to '${pos_webapp_destination_diseases_efo}'"
    gsutil cp ${pos_webapp_source_diseases_efo} ${pos_webapp_destination_diseases_efo}
    log "[DONE] Preparing web application static data context"
}


# --- Main ---
mount_data_volumes
log "Make sure the list of folders needed to operate the postprocessing pipeline exist"
ensure_folders_exist
prepare_webapp_static_data_context
# Run Clickhouse data load in the background and wait for it to finish
log "[--- Run Clickhouse data pipeline ---]"
log "[DEBUG] --- SKIP RUNNING CLICKHOUSE DATA PIPELINE ---"
#cd $( dirname ${pos_path_postprocessing_scripts_entry_point_clickhouse}) ; ./$(basename ${pos_path_postprocessing_scripts_entry_point_clickhouse})
# TODO - Detach Clickhouse storage volume
# TODO - Create Clickhouse storage volume image

# Run Elastic Search data loading process
log "[--- Run Elastic Search data pipeline ---]"
cd $( dirname ${pos_path_postprocessing_scripts_entry_point_elastic_search}) ; ./$(basename ${pos_path_postprocessing_scripts_entry_point_elastic_search})

# TODO - Create Tarballs of Clickhouse and Elastic Search data volumes
# TODO - Upload Tarballs to GCS
# TODO - Create GCP images for the Clickhouse and Elastic Search data volumes
# TODO - Dump all POS pipeline logs to file
log "[--- Dumping all POS pipeline logs to file '${pos_path_logs_startup_script}' ---]"
sudo journalctl -u google-startup-scripts.service > ${pos_path_logs_startup_script}
# Upload POS pipeline logs to GCS
log "[--- Uploading POS pipeline logs to GCS, at '${pos_gcp_path_pos_pipeline_session_logs}' ---]"
gsutil -m rsync -r ${pos_path_logs_postprocessing}/ ${pos_gcp_path_pos_pipeline_session_logs}/