#!/bin/bash

#if [ $# -ne 1 ]; then
#    echo "Usage: $0 <version_tag>"
#    exit 1
#fi

version_tag=21.06.1
project_id=open-targets-eu-dev
underscore_version_tag=${version_tag//[\.]/_}

path_prefix="gs://open-targets-pre-data-releases/${version_tag}/output/etl/parquet"

datasets=$(gsutil -m cat "${path_prefix}/metadata/**/part*" | jq -r '.id' )

bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}
#
for ds in $datasets
do
  echo $ds
  bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.${ds}
#
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

#bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.faersRaw
#bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET faersRaw \
#  "gs://open-targets-pre-data-releases/${version_tag}/output/faers/parquet/raw/part*"

#bq --project_id=${project_id} --location='eu' mk platform_${underscore_version_tag}.faersSignificant
#bq --project_id=${project_id} --dataset_id=platform_${underscore_version_tag} --location='eu' load --autodetect --source_format=PARQUET faersSignificant \
#  "gs://open-targets-pre-data-releases/${version_tag}/output/faers/parquet/significant/part*"
