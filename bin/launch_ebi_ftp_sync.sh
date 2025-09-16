#!/bin/bash

# This script is used to launch the EBI FTP sync process as a job in the cluster.

set -e

SLURM_JOB_SCRIPT=$1
DATA_LOCATION_SOURCE=$2
RELEASE_ID_PROD=$3
IS_PARTNER_INSTANCE=$4
PATH_GCS_CREDENTIALS_FILE=$5

# Check if the required arguments are provided
if [ -z "${SLURM_JOB_SCRIPT}" ] || [ -z "${DATA_LOCATION_SOURCE}" ] || [ -z "${RELEASE_ID_PROD}" ] || [ -z "${IS_PARTNER_INSTANCE}" ] || [ -z "${PATH_GCS_CREDENTIALS_FILE}" ]; then
    echo "Usage: $0 <slurm_job_script> <data_location_source> <release_id_prod> <is_partner_instance> <path_gcs_credentials_file>"
    exit 1
fi

# Environment
export DST_PATH_RELATIVE_OPS="ot-ops"
export DST_PATH_RELATIVE_CREDENTIALS="${DST_PATH_RELATIVE_OPS}/credentials"
export DST_GCP_CREDENTIALS_FILENAME="gcp_credentials.json"
export DST_PATH_RELATIVE_CREDENTIALS_FILE="${DST_PATH_RELATIVE_CREDENTIALS}/${DST_GCP_CREDENTIALS_FILENAME}"
[ -z "${SLURM_USER}" ] && export SLURM_USER=`whoami`
[ -z "${SLURM_QUEUE}" ] && export SLURM_QUEUE="datamover"
[ -z "${EBI_LOGIN_NODE}" ] && export EBI_LOGIN_NODE="codon-slurm-login"
[ -z "${RELEASE_ID_PROD}" ] && export RELEASE_ID_PROD='dev.default_release_id'
[ -z "${DATA_LOCATION_SOURCE}" ] && export DATA_LOCATION_SOURCE="open-targets-pre-data-releases/${RELEASE_ID_PROD}"
[ -z "${IS_PARTNER_INSTANCE}" ] && export IS_PARTNER_INSTANCE=true

# Helpers
function log {
    echo -e "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1"
}

log_heading() {
    tag=$1
    shift
    log "[=[$tag]= ---| $@ |--- ]"
}

log_body() {
    tag=$1
    shift
    log "\t[$tag]---> $@"
}

log_error() {
    log "[ERROR] $@"
}

# Summary of the environment
log_heading "INFO" "Launching EBI FTP sync job"
log_body "INFO" "                              SLURM User: ${SLURM_USER}"
log_body "INFO" "                             SLURM Queue: ${SLURM_QUEUE}"
log_body "INFO" "                          EBI Login Node: ${EBI_LOGIN_NODE}"
log_body "INFO" "                        SLURM Job Script: ${SLURM_JOB_SCRIPT}"
log_body "INFO" "                    Data Source Location: ${DATA_LOCATION_SOURCE}"
log_body "INFO" "                 Release ID (Production): ${RELEASE_ID_PROD}"
log_body "INFO" "                    GCP Credentials file: ${PATH_GCS_CREDENTIALS_FILE}"
log_body "INFO" "      Destination PATH Operations folder: \$HOME/${DST_PATH_RELATIVE_OPS}"
log_body "INFO" "     Destination PATH Credentials folder: \$HOME/${DST_PATH_RELATIVE_CREDENTIALS}"

# Check if it's partner instance
if [ "${IS_PARTNER_INSTANCE}" = true ]; then
    log_body "INFO" "This is a PARTNER INSTANCE, SKIPPING the sync process"
    exit 0
fi

# Prepare the credentials file
log_body "INFO" "Preparing ops folder, \$HOME/${DST_PATH_RELATIVE_OPS} and credentials file, \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}"
cat ${PATH_GCS_CREDENTIALS_FILE} | ssh ${SLURM_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; mkdir -p \$HOME/${DST_PATH_RELATIVE_CREDENTIALS}; chmod -R 750 \$HOME/${DST_PATH_RELATIVE_OPS}; cat - > \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; chmod 640 \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}'"
# Launch the job
log_body "INFO" "Launching the job on the SLURM cluster"
cat ${SLURM_JOB_SCRIPT} | ssh ${SLURM_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; export PATH_OPS_ROOT_FOLDER=\$HOME/${DST_PATH_RELATIVE_OPS}; export PATH_OPS_CREDENTIALS=\$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; export RELEASE_ID_PROD=${RELEASE_ID_PROD}; export DATA_LOCATION_SOURCE=${DATA_LOCATION_SOURCE}; export SLURM_QUEUE=${SLURM_QUEUE}; sbatch --partition=${SLURM_QUEUE}'"