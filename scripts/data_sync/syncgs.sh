#!/bin/bash

path_data_source="gs://${DATA_LOCATION_SOURCE}/"

# TODO - Change the way the command is run
# TODO - Add a check to see if the release is already there
# TODO - Skipped failed matches from literature
# TODO - DO NOT RUN IF THIS IS A PPP INSTANCE
echo "=== Start copying..."
cmd=`gsutil -m rsync -r -x '^input/fda-inputs/*' $path_data_source gs://open-targets-data-releases/${RELEASE_ID_PROD}/`
echo "=== Copying done."