#!/bin/bash

pre_data_release="gs://${GS_SYNC_FROM}/"

echo "=== Start copying..."
cmd=`gsutil rsync -r -x '^input/fda-inputs/*' $pre_data_release gs://open-targets-data-releases/${RELEASE_ID_PROD}/`
echo "=== Copying done."