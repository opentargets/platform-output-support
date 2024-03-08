#!/bin/bash

# This script is used to launch the EBI FTP sync process as a job in the cluster.

set -e

# TODO - DO NOT RUN IF THIS IS A PPP INSTANCE

# Environment
export BASEDIR=$(dirname $0)
export SLURM_JOB_SCRIPT="${BASEDIR}/ftp_sync.sh"
export DST_PATH_RELATIVE_OPS="ot-ops"
export DST_PATH_RELATIVE_CREDENTIALS="${DST_PATH_RELATIVE_OPS}/credentials"
export DST_GCP_CREDENTIALS_FILENAME="gcp_credentials.json"
export DST_PATH_RELATIVE_CREDENTIALS_FILE="${DST_PATH_RELATIVE_CREDENTIALS}/${DST_GCP_CREDENTIALS_FILENAME}"
[ -z "${SLURM_USER}" ] && export SLURM_USER=`whoami`
[ -z "${SLURM_QUEUE}" ] && export SLURM_QUEUE="datamover"
[ -z "${EBI_LOGIN_GATE}" ] && export EBI_LOGIN_GATE="ligate.ebi.ac.uk"
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
log_body "INFO" "                          EBI Login Gate: ${EBI_LOGIN_GATE}"
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
cat ${PATH_GCS_CREDENTIALS_FILE} | ssh -o proxycommand="ssh -p 2244 ${SLURM_USER}@${EBI_LOGIN_GATE} proxy %h" ${SLURM_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; mkdir -p \$HOME/${DST_PATH_RELATIVE_CREDENTIALS}; chmod -R 750 \$HOME/${DST_PATH_RELATIVE_OPS}; cat - > \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; chmod 640 \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}'"
# Launch the job
log_body "INFO" "Launching the job on the SLURM cluster"
cat ${SLURM_JOB_SCRIPT} | ssh -o proxycommand="ssh -p 2244 ${SLURM_USER}@${EBI_LOGIN_GATE} proxy %h" ${SLURM_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; export PATH_OPS_ROOT_FOLDER=\$HOME/${DST_PATH_RELATIVE_OPS}; export PATH_OPS_CREDENTIALS=\$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; export RELEASE_ID_PROD=${RELEASE_ID_PROD}; export DATA_LOCATION_SOURCE=${DATA_LOCATION_SOURCE}; export SLURM_QUEUE=${SLURM_QUEUE}; sbatch --partition=${SLURM_QUEUE}'"