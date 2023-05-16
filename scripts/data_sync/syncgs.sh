#!/bin/bash

path_data_source="gs://${DATA_LOCATION_SOURCE}/"

# TODO - Change the way the command is run
# TODO - Add a check to see if the release is already there
# TODO - Skipped failed matches from literature
# Check if it's partner instance
if [ "${IS_PARTNER_INSTANCE}" = true ]; then
    echo "This is a PARTNER INSTANCE, SKIPPING the sync process"
    exit 0
fi

echo "=== Start copying..."
cmd=`gsutil -m rsync -r -x '^input/fda-inputs/*' $path_data_source gs://open-targets-data-releases/${RELEASE_ID_PROD}/`
echo "=== Copying done."