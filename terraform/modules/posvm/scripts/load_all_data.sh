#!/bin/bash
echo ${ELASTICSEARCH_URI}
echo ${GS_ETL_DATASET}

#This is a prototype. Change when ETL will be stable in the output approach
export RELEASE=${ETL_RELEASE:-""}

echo $PREFIX_DATA
echo $ES
echo $RELEASE

input="/tmp/output_etl_struct.jsonl"
while IFS= read -r line
do
  echo "$line"
  export INPUT=`echo $line | awk -F, '{print $1}'`
  export ID=`echo $line | awk -F, '{print $3}'`
  export INDEX_NAME=`echo $line | awk -F, '{print $2}'`
  export INDEX_SETTINGS=$PREFIX_DATA/`echo $line | awk -F, '{print $4}'`
  echo $INPUT
  echo $ID
  echo $INDEX_NAME
  echo $INDEX_SETTINGS
done < "$input"



# Load evidence
FOLDER_PREFIX="${PREFIX_DATA}/evidence"
FOLDERS=$(ls -1 $FOLDER_PREFIX | grep 'sourceId')

for folder in $FOLDERS; do
  IFS='=' read -ra tokens <<< "$folder"

  token="evidence_datasource_${tokens[1]}"

  full_folder="${FOLDER_PREFIX}/${folder}/"

  export ID='id'
  export INDEX_NAME="${token}"
  export INPUT="${full_folder}"
  export INDEX_SETTINGS=$PREFIX_DATA/index_settings.json
  echo $INDEX_SETTINGS
  /tmp/load_json.sh
done


