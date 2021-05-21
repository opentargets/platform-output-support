#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] POS support VM"

#sudo apt update && sudo apt -y install python3-pip
#sudo pip3 install elasticsearch-loader

sudo sh -c 'apt update && apt -y install wget && apt -y install python3-pip && pip3 install elasticsearch-loader'

mkdir /tmp
wget https://github.com/miku/esbulk/releases/download/v0.7.3/esbulk_0.7.3_amd64.deb
sudo dpkg -i esbulk_0.7.3_amd64.deb

echo ${ELASTICSEARCH_URI}
echo ${GS_ETL_DATASET}
echo "curl here"
curl -X GET  ${ELASTICSEARCH_URI}:9200/_cat/indices; echo

mkdir -p /tmp/data
mkdir -p /tmp/data/so
mkdir -p /tmp/data/faers/

# Copy files locally.
gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/json/* /tmp/data/
gsutil -m cp -r gs://${GS_ETL_DATASET}/so/* /tmp/data/so
gsutil -m cp -r gs://${GS_ETL_DATASET}/faers/json/raw/* /tmp/data/faers/

echo "Copy from GS to local HD"
#gsutil cat  'gs://open-targets-data-releases/21.04/output/etl/json/metadata/**/part*' | jq -r '.resource'
sudo mkdir -p /tmp
cd /tmp
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/load_json.sh
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/load_json_esbulk.sh
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/output_etl_struct.jsonl
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/load_all_data.sh
sudo chmod 555 load_all_data.sh
sudo chmod 555 load_json.sh
sudo chmod 555 load_json_esbulk.sh

sudo wget -O /tmp/data/index_settings.json https://raw.githubusercontent.com/opentargets/platform-etl-backend/master/elasticsearch/index_settings.json
sudo wget -O /tmp/data/index_settings_search_known_drugs.json https://raw.githubusercontent.com/opentargets/platform-etl-backend/master/elasticsearch/index_settings_search_known_drugs.json
sudo wget -O /tmp/data/index_settings_search.json https://raw.githubusercontent.com/opentargets/platform-etl-backend/master/elasticsearch/index_settings_search.json

export ES=${ELASTICSEARCH_URI}:9200
export PREFIX_DATA=/tmp/data/
echo "starting the insertion of data ... Elasticsearch."
time ./load_all_data.sh

sudo echo "done" > /tmp/done.msg


