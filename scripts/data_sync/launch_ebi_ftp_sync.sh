#!/bin/bash

# This script is used to launch the EBI FTP sync process as a job in the cluster.

set -e

# Environment
export BASEDIR=$(dirname $0)
export LSF_JOB_SCRIPT="${BASEDIR}/lsf_ftp_sync.sh"
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

log_heading "INFO" "Launching EBI FTP sync job"
log_body "INFO" "LSF User: ${LSF_USER}"
log_body "INFO" "LSF Queue: ${LSF_QUEUE}"
log_body "INFO" "EBI Login Gate: ${EBI_LOGIN_GATE}"
log_body "INFO" "EBI Login Node: ${EBI_LOGIN_NODE}"
log_body "INFO" "LSF Job Script: ${LSF_JOB_SCRIPT}"
log_body "INFO" "GS Sync From: ${GS_SYNC_FROM}"
log_body "INFO" "Release ID: ${RELEASE_ID_PROD}"
cat ${LSF_JOB_SCRIPT} | ssh -o proxycommand="ssh -p 2244 ${LSF_USER}@${EBI_LOGIN_GATE} proxy %h" ${LSF_USER}@${EBI_LOGIN_NODE} "/bin/bash -c 'source /etc/bashrc; export RELEASE_ID_PROD=${RELEASE_ID_PROD}; export LSF_QUEUE=${LSF_QUEUE}; bsub -q ${LSF_QUEUE}'"