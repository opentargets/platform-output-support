#!/bin/bash
# Startup script for Elastic Search VM Instance

# Logging helper function
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

# Environment variables
gcp_device_disk_clickhouse="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_CH}"
gcp_device_disk_elasticsearch="${GCP_DEVICE_DISK_PREFIX}${DATA_DISK_DEVICE_NAME_ES}"

# Environment summary function
function env_summary() {
  log "Environment summary:"
  log "  PROJECT_ID: ${PROJECT_ID}"
  log "  GC_ZONE: ${GC_ZONE}"
  log "  GS_ETL_DATASET: ${GS_ETL_DATASET}"
  log "  IS_PARTNER_INSTANCE: ${IS_PARTNER_INSTANCE}"
  log "  GS_DIRECT_FILES: ${GS_DIRECT_FILES}"
  log "  GCP_DEVICE_DISK_PREFIX: ${GCP_DEVICE_DISK_PREFIX}"
  log "  DATA_DISK_DEVICE_NAME_CH: ${DATA_DISK_DEVICE_NAME_CH}"
  log "  DATA_DISK_DEVICE_NAME_ES: ${DATA_DISK_DEVICE_NAME_ES}"
  log "  DISK_IMAGE_NAME_CH: ${DISK_IMAGE_NAME_CH}"
  log "  DISK_IMAGE_NAME_ES: ${DISK_IMAGE_NAME_ES}"
  log "  CLICKHOUSE_URI: ${CLICKHOUSE_URI}"
  log "  ELASTICSEARCH_URI: ${ELASTICSEARCH_URI}"
  log "  gcp_device_disk_clickhouse: ${gcp_device_disk_clickhouse}"
  log "  gcp_device_disk_elasticsearch: ${gcp_device_disk_elasticsearch}"
}

#

# Main Script
echo "---> [LAUNCH] POS support VM"
env_summary
# DEBUG - HALT SCRIPT
exit 0






sudo sh -c 'apt update && apt -y install wget && apt -y install python3-pip && pip3 install elasticsearch-loader'



# Install esbulk.
mkdir /tmp
wget https://github.com/miku/esbulk/releases/download/v0.7.3/esbulk_0.7.3_amd64.deb
sudo dpkg -i esbulk_0.7.3_amd64.deb

echo "CH: "${CLICKHOUSE_URI}", ES:"${ELASTICSEARCH_URI}", GS: "${GS_ETL_DATASET}
echo "Partner instance: "${IS_PARTNER_INSTANCE}

#Query the elasticsearch - log purpose
curl -X GET ${ELASTICSEARCH_URI}:9200/_cat/indices
echo

mkdir -p /tmp/data
mkdir -p /tmp/data/so
mkdir -p /tmp/data/mp
mkdir -p /tmp/data/otar_projects
mkdir -p /tmp/data/faers/
mkdir -p /tmp/data/webapp

# Copy files locally. Robust vs streaming
echo "Copy from GS to local HD"
gsutil -m -q cp -r gs://${GS_ETL_DATASET}/etl/json/* /tmp/data/

gsutil -m -q cp -r gs://${GS_ETL_DATASET}/etl/json/fda/significantAdverseDrugReactions/* /tmp/data/faers/

gsutil list -r gs://${GS_DIRECT_FILES} | grep so.json | xargs -t -I % gsutil cp % /tmp/data/so
gsutil list -r gs://${GS_DIRECT_FILES} | grep diseases_efo | xargs -t -I % gsutil cp % gs://${GS_DIRECT_FILES}/webapp/ontology/efo_json/
echo "---> Create the downloads information file object, metadata collection from 'gs://${GS_ETL_DATASET}/metadata/**/*.json' to 'gs://${GS_DIRECT_FILES}/webapp/downloads.json'"
gsutil cat 'gs://${GS_ETL_DATASET}/metadata/**/*.json' >/tmp/data/webapp/downloads.json
gsutil cp /tmp/data/webapp/downloads.json gs://${GS_DIRECT_FILES}/webapp/downloads.json
#TODO: remove in the next release. Used to test the command output
gsutil list -r gs://${GS_DIRECT_FILES} | grep diseases_efo | xargs -t -I % gsutil cp % /tmp/data/
gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/json/otar_projects/* /tmp/data/otar_projects/

sudo mkdir -p /tmp
cd /tmp
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/load_json_esbulk.sh
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/output_etl_struct.jsonl
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/load_all_data.sh
sudo chmod 555 load_all_data.sh
sudo chmod 555 load_json_esbulk.sh

sudo wget -O /tmp/data/index_settings.json https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/ES/index_settings.json
sudo wget -O /tmp/data/index_settings_search_known_drugs.json https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/ES/index_settings_search_known_drugs.json
sudo wget -O /tmp/data/index_settings_search.json https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/ES/index_settings_search.json
sudo wget -O /tmp/data/index_settings_genetics_evidence.json https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/ES/index_settings_genetics_evidence.json

export ES=${ELASTICSEARCH_URI}:9200
export PREFIX_DATA=/tmp/data/
echo "starting the insertion of data ... Elasticsearch."
time ./load_all_data.sh

POLL=1
echo "POLL="$POLL
while [ $POLL != "0" ]; do
  sleep 30
  #allow non zero exit codes since that is what we are checking for
  set +e
  #pipeline script will put a tag on the instance here it checks for this tag
  gcloud --project ${PROJECT_ID} compute instances list --filter='tags:startup-done' >instance_tmp.txt
  cat instance_tmp.txt

  # Check if clickhouse is done with the insertion of the data
  grep ${CLICKHOUSE_URI} instance_tmp.txt
  POLL=$?
  echo "POLL="$POLL

  #disallow non zero exit codes again since that is sensible
  set -e
done

# Get some data to validate loading was successful
es_logs="es_loading_logs.txt"
date >>$es_logs
curl -X GET ${ELASTICSEARCH_URI}:9200/_cat/indices >>$es_logs
gsutil cp $es_logs 'gs://${GS_ETL_DATASET}/pos/'
#stop elasticsearch machine
gcloud compute --project=${PROJECT_ID} instances stop ${ELASTICSEARCH_URI} --zone ${GC_ZONE}

# stop Clickhouse
gcloud compute --project=${PROJECT_ID} instances stop ${CLICKHOUSE_URI} --zone ${GC_ZONE}

NOW=$(date +'%y%m%d-%H%M%S')
echo $NOW
#create image from elasticsearch machine
gcloud compute --project=${PROJECT_ID} images create ${IMAGE_PREFIX}-$NOW-es --source-disk ${ELASTICSEARCH_URI} --family ot-es7 --source-disk-zone ${GC_ZONE}

#create image from clickhouse image
gcloud compute --project=${PROJECT_ID} images create ${IMAGE_PREFIX}-$NOW-ch --source-disk ${CLICKHOUSE_URI} --family ot-ch --source-disk-zone ${GC_ZONE}
