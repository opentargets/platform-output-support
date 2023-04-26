# This file contains helpers to work with the postprocessing pipeline

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Syntactic sugar
alias l="ls -alh"

# Load common configuration script
source ${SCRIPTDIR}/config.sh

# POS operational helpers
alias pos_logs_startup="sudo journalctl -u google-startup-scripts.service"