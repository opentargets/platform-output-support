#!/bin/bash

# This script launches the postprocessing pipeline tasks related to Clickhouse

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Global configuration
source ${SCRIPTDIR}/../config.sh
# Local configuration
source ${SCRIPTDIR}/config.sh

# Helper functions
# Run clickhouse via Docker 
function run_clickhouse() {
  log "[START] Running clickhouse via Docker, using image ${CLICKHOUSE_DOCKER_IMAGE}:${CLICKHOUSE_DOCKER_IMAGE_VERSION}"
  docker run --rm -d \
    --name otp-ch \
    -p 9000:9000 \
    -p 8123:8123 \
    -v ${mount_point_data_clickhouse}:/var/lib/clickhouse \
    -v ${path_logs_clickhouse}:/var/log/clickhouse-server \
    --ulimit nofile=262144:262144 \
    ${CLICKHOUSE_DOCKER_IMAGE}:${CLICKHOUSE_DOCKER_IMAGE_VERSION}
}