# This file contains helpers to work with the postprocessing pipeline

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Syntactic sugar
alias l="ls -alh"

# Load common configuration script
source ${SCRIPTDIR}/config.sh
# Load Clickhouse configuration script (TODO maybe parameterize this in the future)
source ${pos_path_postprocessing_scripts_clickhouse}/config.sh

# POS operational helpers
alias pos_logs_startup="sudo journalctl -u google-startup-scripts.service"
alias pos_logs_startup_tail="sudo journalctl -u google-startup-scripts.service -f"
alias pos_ch_client="docker exec -it ${pos_ch_docker_container_name} clickhouse-client"