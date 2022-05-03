#!/bin/bash
# Job requirements
#BSUB -J ot_platform_ebi_ftp_sync
#BSUB -W 00:05
#BSUB -n 1
#BSUB -M 2G
#BUSB -R rusage[mem=2G]
#BSUB -e /nfs/ftp/private/otftpuser/lsf/logs/%J.err
#BSUB -o /nfs/ftp/private/otftpuser/lsf/logs/%J.out

# This is an LSF job that uploads Open Targets Platform release data to EBI FTP Service

# Defaults
[ -z "${RELEASE_ID_PROD}" ] && export RELEASE_ID_PROD='dev.default_release_id'

# Helpers and environment
alias gen_id='uuidgen | tr '\''[:upper:]'\'' '\''[:lower:]'\'
export session_id_suffix=`gen_id | cut -f5 -d'-'`
export job_name="ot-sync-${RELEASE_ID_PROD}-${session_id_suffix}"
export path_private_base='/nfs/ftp/private/otftpuser'
export path_ebi_ftp_base='/nfs/ftp/pub/databases/opentargets/platform'
export path_ebi_ftp_destination="${path_ebi_ftp_base}/${RELEASE_ID_PROD}"
export path_lsf_base="${path_private_base}/lsf"
export path_lsf_logs="${path_lsf_base}/logs"
export path_lsf_job_workdir="${path_lsf_base}/${job_name}"
export path_lsf_job_logs="${path_lsf_logs}/${job_name}"
export path_lsf_job_stderr="${path_lsf_job_logs}/output.err"
export path_lsf_job_stdout="${path_lsf_job_logs}/output.out"
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
    echo -e "[==================== JOB DATASHEET ======================]"
    echo -e "\t- Release Number                     : ${release_number}"
    echo -e "\t- Job Name                           : ${job_name}"
    echo -e "\t- PATH Private base                  : ${path_private_base}"
    echo -e "\t- PATH EBI FTP base destination      : ${path_ebi_ftp_base}"
    echo -e "\t- PATH LSF base                      : ${path_lsf_base}"
    echo -e "\t- PATH LSF logs                      : ${path_lsf_logs}"
    echo -e "\t- PATH LSF Job workdir               : ${path_lsf_job_workdir}"
    echo -e "\t- PATH LSF Job logs stderr           : ${path_lsf_job_stderr}"
    echo -e "\t- PATH LSF Job logs stdout           : ${path_lsf_job_stdout}"
    echo -e "\t- PATH Data Source                   : ${path_data_source}"
    echo -e "[====================|==============|=====================]"
}

make_dirs() {
  log_body "MKDIR" "Check/Create ${path_lsf_base}"
  sudo -u otftpuser --bash -c "mkdir ${path_lsf_base} && chmod 770 ${path_lsf_base}"
  log_body "MKDIR" "Check/Create ${path_lsf_logs}"
  sudo -u otftpuser --bash -c "mkdir ${path_lsf_logs} && chmod 770 ${path_lsf_logs}"
  log_body "MKDIR" "Check/Create ${path_lsf_job_workdir}"
  sudo -u otftpuser --bash -c "mkdir ${path_lsf_job_workdir} && chmod 770 ${path_lsf_job_workdir}"
  log_body "MKDIR" "Check/Create ${path_lsf_job_logs}"
  sudo -u otftpuser --bash -c "mkdir ${path_lsf_job_logs} && chmod 770 ${path_lsf_job_logs}"
  log_body "MKDIR" "Check/Create ${path_ebi_ftp_destination}"
  sudo -u otftpuser --bash -c "mkdir ${path_ebi_ftp_destination} && chmod 770 ${path_ebi_ftp_destination}"
}

print_summary
log_heading "ENV" "This is the Job environment variables"
env
#log_heading "FILESYSTEM" "Preparing destination folders"
#make_dirs
#log_heading "JOB" "END OF JOB ${job_name}"