#!/bin/bash

# Arguments
DATA_LOCATION_SOURCE=$1
DATA_LOCATION_TARGET=$2
IS_PARTNER_INSTANCE=$3

# Check if the required arguments are provided
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

# Check if it's partner instance
if [ "${IS_PARTNER_INSTANCE}" = true ]; then
    echo "This is a PPP INSTANCE."
fi

echo "=== Syncing data from: ${DATA_LOCATION_SOURCE} --> ${DATA_LOCATION_TARGET}"
gcloud storage rsync -r $DATA_LOCATION_SOURCE $DATA_LOCATION_TARGET
echo "=== Sync complete."
