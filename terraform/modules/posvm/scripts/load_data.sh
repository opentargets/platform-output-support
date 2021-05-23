#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] POS support VM"

#sudo apt update && sudo apt -y install python3-pip
#sudo pip3 install elasticsearch-loader

sudo sh -c 'apt update && apt -y install wget && apt -y install python3-pip && pip3 install elasticsearch-loader'

mkdir /tmp
wget https://github.com/miku/esbulk/releases/download/v0.7.3/esbulk_0.7.3_amd64.deb
sudo dpkg -i esbulk_0.7.3_amd64.deb

echo ${CLICKHOUSE_URI}
echo ${ELASTICSEARCH_URI}
echo ${GS_ETL_DATASET}
echo ${GC_ZONE}
echo ${PROJECT_ID}

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


POLL=1
echo "POLL="$POLL
while [ $POLL != "0" ]
do
  sleep 30
  #allow non zero exit codes since that is what we are checking for
  set +e
  #pipeline script will put a tag on the instance here it checks for this tag
  gcloud --project ${PROJECT_ID} compute instances list --filter='tags:startup-done' > instance_tmp.txt
  cat instance_tmp.txt

  grep ${CLICKHOUSE_URI} instance_tmp.txt
  POLL=$?
  echo "POLL="$POLL

  #disallow non zero exit codes again since that is sensible
  set -e
done

#stop elasticsearch machine
gcloud compute --project=${PROJECT_ID} instances stop ${ELASTICSEARCH_URI} --zone ${GC_ZONE}

# Clickhouse
gcloud compute --project=${PROJECT_ID} instances stop ${CLICKHOUSE_URI}	--zone ${GC_ZONE}

#create image from elasticsearch machine
gcloud compute --project=${PROJECT_ID}  images create platform-$NOW-cinzia-es  --source-disk ${ELASTICSEARCH_URI}  --family ot-es7     --source-disk-zone ${GC_ZONE}

