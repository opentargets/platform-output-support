#!/bin/bash
# Job requirements
#BSUB -J ot_platform_ebi_ftp_sync
#BSUB -W 03:00
#BSUB -n 2
#BSUB -M 4G
#BUSB -R rusage[mem=4G]
#BSUB -e /nfs/ftp/private/otftpuser/lsf/logs/ot_platform_ebi_ftp_sync-%J.err
#BSUB -o /nfs/ftp/private/otftpuser/lsf/logs/ot_platform_ebi_ftp_sync-%J.out
#BUSB -B

# This is an LSF job that uploads Open Targets Platform release data to EBI FTP Service

# Defaults
[ -z "${RELEASE_ID_PROD}" ] && export RELEASE_ID_PROD='dev.default_release_id'
[ -z "${GS_SYNC_FROM}" ] && export GS_SYNC_FROM="open-targets-pre-data-releases/${RELEASE_ID_PROD}"

# Helpers and environment
#alias gen_id='uuidgen | tr '\''[:upper:]'\'' '\''[:lower:]'\'
#export session_id_suffix=`gen_id | cut -f5 -d'-'`
#export session_id_suffix="${LSB_BATCH_JID}"
#export job_name="ot-sync-${RELEASE_ID_PROD}-${session_id_suffix}"
export job_name="${LSB_JOBNAME}-${LSB_BATCH_JID}"
export path_private_base='/nfs/ftp/private/otftpuser'
export path_private_base_ftp_upload="${path_private_base}/opentargets_ebi_ftp_upload"
export path_private_staging_folder="${path_private_base_ftp_upload}/${RELEASE_ID_PROD}"
export path_ebi_ftp_base='/nfs/ftp/pub/databases/opentargets/platform'
export path_ebi_ftp_destination="${path_ebi_ftp_base}/${RELEASE_ID_PROD}"
export path_ebi_ftp_destination_latest="${path_ebi_ftp_base}/latest"
export path_lsf_base="${path_private_base}/lsf"
export path_lsf_logs="${path_lsf_base}/logs"
export path_lsf_job_workdir="${path_lsf_base}/${job_name}"
export path_lsf_job_logs="${path_lsf_logs}/${job_name}"
export path_lsf_job_stderr="${path_lsf_job_logs}/output.err"
export path_lsf_job_stdout="${path_lsf_job_logs}/output.out"
export path_lsf_job_bsub_stderr="${path_lsf_logs}/${job_name}.err"
export path_lsf_job_bsub_stdout="${path_lsf_logs}/${job_name}.out"
export path_data_source="gs://${GS_SYNC_FROM}/"


log_heading() {
    tag=$1
    shift
    echo -e "[=[$tag]= ---| $@ |--- ]"
}

log_body() {
    tag=$1
    shift
    echo -e "\t[$tag]---> $@"
}

log_error() {
    echo -e "[ERROR] $@"
}

print_summary() {
    echo -e "[=================================== JOB DATASHEET =====================================]"
    echo -e "\t- Release Number                     : ${RELEASE_ID_PROD}"
    echo -e "\t- Job Name                           : ${job_name}"
    echo -e "\t- PATH Private base                  : ${path_private_base}"
    echo -e "\t- PATH Private staging folder        : ${path_private_staging_folder}"
    echo -e "\t- PATH EBI FTP base destination      : ${path_ebi_ftp_base}"
    echo -e "\t- PATH EBI FTP destination folder    : ${path_ebi_ftp_destination}"
    echo -e "\t- PATH EBI FTP destination latest    : ${path_ebi_ftp_destination_latest}"
    echo -e "\t- PATH LSF base                      : ${path_lsf_base}"
    echo -e "\t- PATH LSF logs                      : ${path_lsf_logs}"
    echo -e "\t- PATH LSF Job workdir               : ${path_lsf_job_workdir}"
    echo -e "\t- PATH LSF Job logs stderr           : ${path_lsf_job_stderr}"
    echo -e "\t- PATH LSF Job logs stdout           : ${path_lsf_job_stdout}"
    echo -e "\t- PATH LSF BSUB Job logs stderr      : ${path_lsf_job_bsub_stderr}"
    echo -e "\t- PATH LSF BSUB Job logs stdout      : ${path_lsf_job_bsub_stdout}"
    echo -e "\t- PATH Data Source                   : ${path_data_source}"
    echo -e "[===================================|==============|====================================]"
}

make_dirs() {
  log_body "MKDIR" "Check/Create ${path_lsf_base}"
  sudo -u otftpuser -- bash -c "mkdir ${path_lsf_base} && chmod 770 ${path_lsf_base}"
  log_body "MKDIR" "Check/Create ${path_lsf_logs}"
  sudo -u otftpuser -- bash -c "mkdir ${path_lsf_logs} && chmod 770 ${path_lsf_logs}"
  log_body "MKDIR" "Check/Create ${path_lsf_job_workdir}"
  sudo -u otftpuser -- bash -c "mkdir ${path_lsf_job_workdir} && chmod 770 ${path_lsf_job_workdir}"
  log_body "MKDIR" "Check/Create ${path_lsf_job_logs}"
  sudo -u otftpuser -- bash -c "mkdir ${path_lsf_job_logs} && chmod 770 ${path_lsf_job_logs}"
  log_body "MKDIR" "Check/Create ${path_ebi_ftp_destination}"
  sudo -u otftpuser -- bash -c "mkdir ${path_ebi_ftp_destination} && chmod 775 ${path_ebi_ftp_destination}"
  log_body "MKDIR" "Check/Create ${path_private_staging_folder}"
  sudo -u otftpuser -- bash -c "mkdir ${path_private_staging_folder} && chmod 770 ${path_private_staging_folder}"
}

print_summary
#log_heading "ENV" "This is the Job environment variables"
#env
log_heading "FILESYSTEM" "Preparing destination folders"
make_dirs
log_heading "GCP" "Copy source data from '${path_data_source}' ---> to ---> '${path_private_staging_folder}'"
CLOUDSDK_PYTHON=/nfs/production/opentargets/anaconda3/bin/python /nfs/production/opentargets/google-cloud-sdk/bin/gsutil -m -u open-targets-prod rsync -r -x ^input/fda-inputs/* ${path_data_source} ${path_private_staging_folder}/
log_heading "PERMISSIONS" "Adjusting file tree permissions at '${path_private_staging_folder}'"
# TODO
log_heading "RSYNC" "Sync data from '${path_private_staging_folder}' ---> to ---> '${path_ebi_ftp_destination}'"
# TODO
log_heading "LATEST" "Update 'latest' link at '${path_ebi_ftp_destination_latest}' to point to '${path_ebi_ftp_destination}'"
# TODO
log_heading "SYNC" "Start a sync of the FTP data from HX staging area to the OY and PG London storages"
# TODO
log_heading "JOB" "END OF JOB ${job_name}"