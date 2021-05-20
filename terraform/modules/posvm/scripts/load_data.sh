#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] POS support VM"

#sudo apt update && sudo apt -y install python3-pip
#sudo pip3 install elasticsearch-loader

sudo sh -c 'apt update && apt -y install python3-pip && pip3 install elasticsearch-loader && pip3 install jq'


echo ${ELASTICSEARCH_URI}
echo ${GS_ETL_DATASET}
echo "curl here"
curl -X GET  ${ELASTICSEARCH_URI}:9200/_cat/indices; echo

mkdir -p /tmp/data
mkdir -p /tmp/data/so
mkdir -p /tmp/data/faers/

# Copy files locally.
gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/* /tmp/data/
gsutil -m cp -r gs://${GS_ETL_DATASET}/so/* /tmp/data/so
gsutil -m cp -r gs://${GS_ETL_DATASET}/faers/* /tmp/data/faers/

echo "Copy from GS to local HD"
#gsutil cat  'gs://open-targets-data-releases/21.04/output/etl/json/metadata/**/part*' | jq -r '.resource'
sudo mkdir -p /tmp
cd tmp
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/load_json.sh
sudo chmod 555 load_data.sh

sudo echo "done" > /tmp/done.msg


