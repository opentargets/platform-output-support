#!/bin/bash

# This script is used to launch the EBI FTP sync process as a job in the cluster.

set -e

# Environment
export BASEDIR=$(dirname $0)
export LSF_JOB_SCRIPT="${BASEDIR}/lsf_ftp_sync.sh"
export DST_PATH_RELATIVE_OPS="ot-ops"
export DST_PATH_RELATIVE_CREDENTIALS="${DST_PATH_RELATIVE_OPS}/credentials"
export DST_GCP_CREDENTIALS_FILENAME="gcp_credentials.json"
export DST_PATH_RELATIVE_CREDENTIALS_FILE="${DST_PATH_RELATIVE_CREDENTIALS}/${DST_GCP_CREDENTIALS_FILENAME}"
[ -z "${LSF_USER}" ] && export LSF_USER=`whoami`
[ -z "${LSF_QUEUE}" ] && export LSF_QUEUE="datamover"
[ -z "${EBI_LOGIN_GATE}" ] && export EBI_LOGIN_GATE="ligate.ebi.ac.uk"
[ -z "${EBI_LOGIN_NODE}" ] && export EBI_LOGIN_NODE="codon-login-02"
[ -z "${RELEASE_ID_PROD}" ] && export RELEASE_ID_PROD='dev.default_release_id'
[ -z "${GS_SYNC_FROM}" ] && export GS_SYNC_FROM="open-targets-pre-data-releases/${RELEASE_ID_PROD}"

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
log_body "INFO" "LSF User: ${LSF_USER}"
log_body "INFO" "LSF Queue: ${LSF_QUEUE}"
log_body "INFO" "EBI Login Gate: ${EBI_LOGIN_GATE}"
log_body "INFO" "EBI Login Node: ${EBI_LOGIN_NODE}"
log_body "INFO" "LSF Job Script: ${LSF_JOB_SCRIPT}"
log_body "INFO" "GS Sync From: ${GS_SYNC_FROM}"
log_body "INFO" "Release ID: ${RELEASE_ID_PROD}"
log_body "INFO" "GCP Credentials file: ${PATH_GCS_CREDENTIALS_FILE}"
log_body "INFO" "Destination PATH Operations folder: \$HOME/${DST_PATH_RELATIVE_OPS}"
log_body "INFO" "Destination PATH Credentials folder: \$HOME/${DST_PATH_RELATIVE_CREDENTIALS}"

# Prepare the credentials file
log_body "INFO" "Preparing ops folder, \$HOME/${DST_PATH_RELATIVE_OPS} and credentials file, \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}"
cat ${PATH_GCS_CREDENTIALS_FILE} | ssh -o proxycommand="ssh -p 2244 ${LSF_USER}@${EBI_LOGIN_GATE} proxy %h" ${LSF_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; mkdir -p \$HOME/${DST_PATH_RELATIVE_CREDENTIALS}; chmod -R 750 \$HOME/${DST_PATH_RELATIVE_OPS}; cat - > \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; chmod 640 \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}'"
# Copy the credentials file
#log_body "INFO" "Copying the credentials file, from ${PATH_GCS_CREDENTIALS_FILE} to \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}"
#cat ${PATH_GCS_CREDENTIALS_FILE} | ssh -o proxycommand="ssh -p 2244 ${LSF_USER}@${EBI_LOGIN_GATE} proxy %h" ${LSF_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; cat - > \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; chmod 640 \$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}'"
# Launch the job
log_body "INFO" "Launching the job on the LSF cluster"
cat ${LSF_JOB_SCRIPT} | ssh -o proxycommand="ssh -p 2244 ${LSF_USER}@${EBI_LOGIN_GATE} proxy %h" ${LSF_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; export PATH_OPS_ROOT_FOLDER=\$HOME/${DST_PATH_RELATIVE_OPS}; export PATH_OPS_CREDENTIALS=\$HOME/${DST_PATH_RELATIVE_CREDENTIALS_FILE}; export RELEASE_ID_PROD=${RELEASE_ID_PROD}; export LSF_QUEUE=${LSF_QUEUE}; bsub -q ${LSF_QUEUE}'"