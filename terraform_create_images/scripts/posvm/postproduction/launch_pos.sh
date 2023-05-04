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

# Create the metadata information for downloads in the web application
function create_webapp_downloads_metadata() {
    log "[START] Creating web application downloads metadata at '${pos_webapp_destination_downloads_metadata}', source data at '${pos_data_release_path_metadata_root}'"
    gsutil cat "${pos_data_release_path_metadata_root}/**/*.json" | gsutil cp - ${pos_webapp_destination_downloads_metadata}
    log "[DONE] Creating web application downloads metadata"
}

# Run the data ingestion pipeline for Clickhouse and Elastic Search
function run_data_ingestion_pipeline() {
    log "[START] Running data ingestion pipeline"
    # TODO - Parallelize the data ingestion pipeline
    # Run Clickhouse data load in the background and wait for it to finish
    log "[--- Launch Clickhouse data pipeline ---]"
    current_dir=`pwd`
    cd $( dirname ${pos_path_postprocessing_scripts_entry_point_clickhouse})
    ./$(basename ${pos_path_postprocessing_scripts_entry_point_clickhouse})

    # Run Elastic Search data loading process
    log "[--- Launch Elastic Search data pipeline ---]"
    #cd $( dirname ${pos_path_postprocessing_scripts_entry_point_elastic_search})
    #./$(basename ${pos_path_postprocessing_scripts_entry_point_elastic_search})
    cd ${current_dir}
}

# Create tarball from given source local path into given destination GCS path
function create_tarball() {
    local path_source=$1
    local path_destination=$2
    log "[START] Creating tarball from '${path_source}' to '${path_destination}'"
    tar czf - -C ${path_source} . | gsutil cp - ${path_destination}
    log "[DONE] Creating tarball from '${path_source}' to '${path_destination}'"
}

# Create the disk data tarballs for Clickhouse and Elastic Search
function create_disk_data_tarballs() {
    log "[START] Creating disk data tarballs for Clickhouse and Elastic Search"
    # TODO - Create Tarballs of Clickhouse and Elastic Search data volumes
    create_tarball "${pos_mount_point_data_clickhouse}" "${pos_data_release_path_disk_images_root}/${pos_data_disk_tarball_clickhouse}"
    create_tarball "${pos_mount_point_data_elasticsearch}" "${pos_data_release_path_disk_images_root}/${pos_data_disk_tarball_elastic_earch}"
    log "[DONE] Creating disk data tarballs for Clickhouse and Elastic Search"
}

# Create GCP image for the given source GCP disk name and zone, using the given image name and family
function create_gcp_image() {
    local gcp_disk_name=$1
    local gcp_disk_zone=$2
    local gcp_image_name=$3
    local gcp_image_family=$4
    local gcp_snapshot_name="${gcp_disk_name}-snapshot"

    log "[START] Creating GCP snapshot '${gcp_snapshot_name}' from GCP disk '${gcp_disk_name}' in zone '${gcp_disk_zone}'"
    gcloud compute disks snapshot ${gcp_disk_name} \
        --zone ${gcp_disk_zone} \
        --snapshot-names ${gcp_snapshot_name}
    log "[DONE] Creating GCP snapshot '${gcp_snapshot_name}' from GCP disk '${gcp_disk_name}' in zone '${gcp_disk_zone}'"

    log "[START] Creating GCP image '${gcp_image_name}' from GCP snapshot '${gcp_snapshot_name}'"
    gcloud compute images create ${gcp_image_name} \
        --source-snapshot ${gcp_snapshot_name} \
        --family ${gcp_image_family}
    log "[DONE] Creating GCP image '${gcp_image_name}' from GCP snapshot '${gcp_snapshot_name}'"

    log "[START] Deleting GCP snapshot '${gcp_snapshot_name}'"
    gcloud compute snapshots delete ${gcp_snapshot_name} --quiet
    log "[DONE] Deleting GCP snapshot '${gcp_snapshot_name}'"
}


# Create GCP images for the Clickhouse and Elastic Search data volumes
function create_gcp_images() {
    log "[START] Creating GCP images for the Clickhouse and Elastic Search data volumes"
    # Unmount data disks for Clickhouse and Elastic Search
    log "[INFO] Unmounting data disk for Clickhouse, from '${pos_mount_point_data_clickhouse}'"
    umount ${pos_mount_point_data_clickhouse}
    log "[INFO] Unmounting data disk for Elastic Search, from '${pos_mount_point_data_elasticsearch}'"
    umount ${pos_mount_point_data_elasticsearch}
    create_gcp_image ${pos_disk_image_name_ch} ${pos_gcp_zone} ${pos_disk_image_name_ch} ${pos_disk_image_family_ch}
    create_gcp_image ${pos_disk_image_name_es} ${pos_gcp_zone} ${pos_disk_image_name_es} ${pos_disk_image_family_es}
    log "[DONE] Creating GCP images for the Clickhouse and Elastic Search data volumes"
}


# --- Main ---
mount_data_volumes
log "Make sure the list of folders needed to operate the postprocessing pipeline exist"
ensure_folders_exist
prepare_webapp_static_data_context
create_webapp_downloads_metadata
run_data_ingestion_pipeline
# Create Tarballs of Clickhouse and Elastic Search data volumes
create_disk_data_tarballs
# Create GCP images for the Clickhouse and Elastic Search data volumes
# create_gcp_images
# Dump all POS pipeline logs to file
log "[--- Dumping all POS pipeline logs to file '${pos_path_logs_startup_script}' ---]"
sudo journalctl -u google-startup-scripts.service > ${pos_path_logs_startup_script}
# Upload POS pipeline logs to GCS
log "[--- Uploading POS pipeline logs to GCS, at '${pos_gcp_path_pos_pipeline_session_logs}' ---]"
gsutil -m rsync -r ${pos_path_logs_postprocessing}/ ${pos_gcp_path_pos_pipeline_session_logs}/
