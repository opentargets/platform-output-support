#!/bin/bash

DATA_LOCATION_SOURCE=$1
DATA_LOCATION_TARGET=$2
IS_PARTNER_INSTANCE=$3

if [ -z "${DATA_LOCATION_SOURCE}" ] || [ -z "${DATA_LOCATION_TARGET}" ] || [ -z "${IS_PARTNER_INSTANCE}" ]; then
    echo "Usage: $0 <data_location_source> <data_location_target> <is_partner_instance>"
    exit 1
fi


function add_trailing_slash {
    local path=$1
    if [[ "${path}" != */ ]]; then
        path="${path}/"
    fi
    echo "${path}"
}

DATA_LOCATION_SOURCE=$(add_trailing_slash "${DATA_LOCATION_SOURCE}")
DATA_LOCATION_TARGET=$(add_trailing_slash "${DATA_LOCATION_TARGET}")

echo $DATA_LOCATION_SOURCE
echo $DATA_LOCATION_TARGET


# Check if it's partner instance
if [ "${IS_PARTNER_INSTANCE}" = true ]; then
    echo "This is a PARTNER INSTANCE, SKIPPING the sync process"
    exit 0
fi

# TODO: check which patterns to exclude
# TODO: remove dry-run flag
echo "=== Start copying..."
gcloud storage rsync -r --dry-run -x '^input/fda-inputs/*' -x '^output/etl/parquet/failedMatches/*' -x '^output/etl/json/failedMatches/*' $DATA_LOCATION_SOURCE $DATA_LOCATION_TARGET
echo "=== Copying done."