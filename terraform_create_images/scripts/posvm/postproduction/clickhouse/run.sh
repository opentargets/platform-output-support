#!/bin/bash

# This script launches the postprocessing pipeline tasks related to Clickhouse

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Global configuration
source ${SCRIPTDIR}/../config.sh
# Local configuration
source ${SCRIPTDIR}/config.sh

