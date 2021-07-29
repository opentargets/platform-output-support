#!/bin/bash

version_tag=${RELEASE_ID}
project_id=${PROJECT_ID}
underscore_version_tag=${version_tag//[\.]/_}
path_prefix="gs://${GS_ETL_DATASET}/etl/parquet"

datasets=$(gsutil -m cat "${path_prefix}/metadata/**/part*" | jq -r '.id' )

bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}

for ds in $datasets
do
  echo $ds
  bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.${ds}

  if [[ $ds = evidence* ]]
  then
    bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET \
      --hive_partitioning_mode=STRINGS \
      --hive_partitioning_source_uri_prefix="${path_prefix}/${ds}/" ${ds}  "${path_prefix}/${ds}/sourceId*"
  else
    bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET ${ds} \
      "${path_prefix}/${ds}/part*"
  fi
done

bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.faersRaw
bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET faersRaw \
 "gs://${GS_ETL_DATASET}/faers/parquet/raw/part*"

bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.faersSignificant
bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET faersSignificant \
  "gs://${GS_ETL_DATASET}/faers/parquet/significant/part*"


# Adding allUserAuth roles
bq show --format=prettyjson ${project_id}:platform_${underscore_version_tag} > platform_${underscore_version_tag}_schema.json
jq --argjson groupInfo '{"role":"roles/bigquery.metadataViewer", "specialGroup": "allAuthenticatedUsers"}' '.access += [$groupInfo]' platform_${underscore_version_tag}_schema.json > platform_${underscore_version_tag}_meta.json
jq --argjson groupInfo '{"role":"READER", "specialGroup": "allAuthenticatedUsers"}' '.access += [$groupInfo]' platform_${underscore_version_tag}_meta.json > platform_${underscore_version_tag}_new_schema.json

bq update --source platform_${underscore_version_tag}_new_schema.json ${project_id}:platform_${underscore_version_tag}

rm platform_${underscore_version_tag}_schema.json
rm platform_${underscore_version_tag}_meta.json
rm platform_${underscore_version_tag}_new_schema.json

# Debug: view the new roles for the BiqQuery dataset
#bq show --format=prettyjson ${project_id}:platform_${underscore_version_tag}
