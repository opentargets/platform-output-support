#!/bin/bash

version_tag=${RELEASE_ID}
project_id=${PROJECT_ID}
path_prefix="gs://${GS_ETL_DATASET}/etl/parquet"

if [ ${project_id} == "open-targets-prod" ]; then
    echo "Production - no suffix - allAuthenticatedUsers ON"
    suffix=""
else
    echo "Dev - suffix dev - allAuthenticatedUsers OFF"
    suffix="_dev"
fi

bq --project_id=${project_id} --location='eu' rm -f -r platform${suffix}
bq --project_id=${project_id} --location='eu' mk platform${suffix}

echo ${version_tag} > platform_sync_v.csv
bq --project_id=${project_id} --location='eu' mk platform${suffix}.ot_release
bq --project_id=${project_id} --dataset_id=platform${suffix} --location='eu' load platform${suffix}.ot_release platform_sync_v.csv release:string

datasets=$(curl -X GET https://raw.githubusercontent.com/opentargets/platform-app/main/src/pages/DownloadsPage/dataset-mappings.json | jq -r '.[] | select( .include_in_bq == true) | .id ')

for ds in $datasets
do
  echo "[DATASET] Loading '$ds'"

  gsutil list $path_prefix"/**" | grep SUCCESS | grep -v metadata | grep -v errors | grep $ds"/" | sed 's/_SUCCESS//g' 2> /dev/null || true
  status=$?

  if [[ $status == 0 ]]; then
    gssource=$(gsutil list $path_prefix"/**" | grep SUCCESS | grep -v metadata | grep -v errors | grep $ds"/" | sed 's/_SUCCESS//g')
    bq --project_id=${project_id} --location='eu' mk platform${suffix}.${ds}

    if [[ $ds = evidence* ]]
    then
      bq --project_id=${project_id} --dataset_id=platform${suffix} --location='eu' load --autodetect --source_format=PARQUET \
        --hive_partitioning_mode=STRINGS \
        --hive_partitioning_source_uri_prefix="${path_prefix}/${ds}/" ${ds}  "${gssource}sourceId*"
    else
      bq --project_id=${project_id} --dataset_id=platform${suffix} --location='eu' load --autodetect --source_format=PARQUET ${ds} \
        "${gssource}part*"
    fi
  else
     echo "=== ERROR " $ds ": table does not exist"
  fi
done

# Adding allUserAuth roles
if [ ${project_id} == "open-targets-prod" ]; then
  bq show --format=prettyjson ${project_id}:platform > platform_schema.json
  jq --argjson groupInfo '{"role":"roles/bigquery.metadataViewer", "specialGroup": "allAuthenticatedUsers"}' '.access += [$groupInfo]' platform_schema.json > platform_meta.json
  jq --argjson groupInfo '{"role":"READER", "specialGroup": "allAuthenticatedUsers"}' '.access += [$groupInfo]' platform_meta.json > platform_new_schema.json

  bq update --source platform_new_schema.json ${project_id}:platform

  rm platform_sync_v.csv
  rm platform_schema.json
  rm platform_meta.json
  rm platform_new_schema.json
else
    echo "The dataset must not be visible: allAuthenticatedUsers OFF"
fi

# Debug: view the new roles for the BiqQuery dataset
#bq show --format=prettyjson ${project_id}:platform_${underscore_version_tag}
