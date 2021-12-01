#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] POS support VM"

sudo sh -c 'apt update && apt -y install wget && apt -y install python3-pip && pip3 install elasticsearch-loader'

# Install esbulk.
mkdir /tmp
wget https://github.com/miku/esbulk/releases/download/v0.7.3/esbulk_0.7.3_amd64.deb
sudo dpkg -i esbulk_0.7.3_amd64.deb

echo "CH: "${CLICKHOUSE_URI}", ES:"${ELASTICSEARCH_URI}", GS: "${GS_ETL_DATASET}
echo "Partner instance: "${IS_PARTNER_INSTANCE}

#Query the elasticsearch - log purpose
curl -X GET  ${ELASTICSEARCH_URI}:9200/_cat/indices; echo

mkdir -p /tmp/data
mkdir -p /tmp/data/so
mkdir -p /tmp/data/mp
mkdir -p /tmp/data/otar_projects
mkdir -p /tmp/data/faers/

# Copy files locally. Robust vs streaming
echo "Copy from GS to local HD"
gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/json/* /tmp/data/

gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/json/fda/significantAdverseDrugReactions/* /tmp/data/faers/
#gsutil -m cp -r gs://${GS_ETL_DATASET}/so/* /tmp/data/so
gsutil list -r gs://${GS_DIRECT_FILES} | grep so.json | xargs -t -I % gsutil cp %  /tmp/data/so
gsutil list -r gs://${GS_DIRECT_FILES} | grep diseases_efo | xargs -t -I % gsutil cp %  gs://${GS_DIRECT_FILES}/webapp/ontology/efo_json/
#TODO: remove in the next release. Used to test the command output
gsutil list -r gs://${GS_DIRECT_FILES} | grep diseases_efo | xargs -t  -I % gsutil cp %  /tmp/data/
gsutil -m cp -r gs://${GS_ETL_DATASET}/etl/json/otar_projects/* /tmp/data/otar_projects/

sudo mkdir -p /tmp
cd /tmp
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/load_json_esbulk.sh
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/output_etl_struct.jsonl
sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform_create_images/modules/posvm/scripts/load_all_data.sh
sudo chmod 555 load_all_data.sh
sudo chmod 555 load_json_esbulk.sh

# If esbulk gives problem try to use elasticsearch_loader
#sudo wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/terraform/modules/posvm/scripts/load_json.sh
#sudo chmod 555 load_json.sh


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

  # Check if clickhouse is done with the insertion of the data
  grep ${CLICKHOUSE_URI} instance_tmp.txt
  POLL=$?
  echo "POLL="$POLL

  #disallow non zero exit codes again since that is sensible
  set -e
done

#stop elasticsearch machine
gcloud compute --project=${PROJECT_ID} instances stop ${ELASTICSEARCH_URI} --zone ${GC_ZONE}

# stop Clickhouse
gcloud compute --project=${PROJECT_ID} instances stop ${CLICKHOUSE_URI}	--zone ${GC_ZONE}

NOW=`date +'%y%m%d-%H%M%S'`
echo $NOW
#create image from elasticsearch machine
gcloud compute --project=${PROJECT_ID}  images create ${IMAGE_PREFIX}-$NOW-es  --source-disk ${ELASTICSEARCH_URI}  --family ot-es7     --source-disk-zone ${GC_ZONE}

#create image from clickhouse image
gcloud compute --project=${PROJECT_ID}  images create ${IMAGE_PREFIX}-$NOW-ch  --source-disk ${CLICKHOUSE_URI}  --family ot-ch     --source-disk-zone ${GC_ZONE}

if [ ${IS_PARTNER_INSTANCE} == false ]; then
 echo "Platform Create VMs. No partner instance"
 gcloud --project ${PROJECT_ID} \
    beta compute instances create ${IMAGE_PREFIX}-$NOW-es-vm \
    --zone=${GC_ZONE} \
    --image-project ${PROJECT_ID} \
    --image ${IMAGE_PREFIX}-$NOW-es \
    --machine-type=e2-highmem-4 \
    --scopes compute-rw,storage-rw

 #--network-tier=PREMIUM --scopes=https://www.googleapis.com/auth/cloud-platform

 gcloud --project ${PROJECT_ID} \
    compute instances create ${IMAGE_PREFIX}-$NOW-ch-vm \
    --zone=${GC_ZONE} \
    --machine-type=e2-custom-4-26624 \
    --image-project ${PROJECT_ID} \
    --image ${IMAGE_PREFIX}-$NOW-ch \
    --scopes compute-rw,storage-rw

 sudo wget -O /tmp/api_app.yaml https://raw.githubusercontent.com/opentargets/platform-api-beta/master/app.yaml
sudo cat > /tmp/custom.yaml <<EOF_A
env_variables:
  ELASTICSEARCH_HOST: "${IMAGE_PREFIX}-$NOW-es-vm.c.open-targets-eu-dev.internal"
  SLICK_CLICKHOUSE_URL: "${IMAGE_PREFIX}-$NOW-ch-vm.c.open-targets-eu-dev.internal:8123"

EOF_A

cat /tmp/api_app.yaml /tmp/custom.yaml > /tmp/api_custom.yaml

#eu.gcr.io/open-targets-eu-dev/default.master:latest
#eu.gcr.io/open-targets-eu-dev/appengine/api-beta.pos-test:latest
gcloud --project=open-targets-eu-dev app deploy /tmp/api_custom.yaml \
    --image-url eu.gcr.io/open-targets-eu-dev/default.master:latest \
    --no-promote \
    --quiet \
    -v pos-test
fi