#!/bin/bash

set -x
set -e


function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

function install_packages() {
    apt-get remove -y --purge man-db
    apt-get update -y
    apt-get install -y wget vim curl git htop pigz ca-certificates gnupg lsb-release 

    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -y 
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    usermod -aG docker ${POS_USER_NAME}

    export HOME=/home/${POS_USER_NAME}
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env"
    git clone https://github.com/opentargets/platform-output-support.git /opt/platform-output-support
    cd /opt/platform-output-support
    git checkout ${BRANCH}
    chgrp -R google-sudoers /opt/platform-output-support
    chmod -R g+rw /opt/platform-output-support
    curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/pos_config" -H "Metadata-Flavor: Google" > /etc/opt/pos_config.yaml
    chgrp -R google-sudoers /var/log
    chmod -R g+rw /var/log
}


function mount_disk() {
  local disk_name=$1
  local mount_point=$2
  # Format the disk using ext4 with no reserved blocks
  prefix="/dev/disk/by-id/google-"
  device_name="$${prefix}$${disk_name}"
  if [[ ${FORMAT_DISK} == true ]]; then 
    log "Formatting disk $${device_name} with ext4"
    mkfs.ext4 -m 0 $${device_name}
  else
    log "Disk $${device_name} will not be formatted"
  fi
  # Mount the disk
  log "Mounting disk $${device_name} to $${mount_point}"
  mkdir -p $${mount_point}
  mount -o defaults $${device_name} $${mount_point}
  chgrp -R google-sudoers $${mount_point}
}

function uv_run() {
    step=$1
    processes=$2
    if [ -z "$processes" ]; then
        processes=10
    fi
    uv --directory /opt/platform-output-support run pos -c /etc/opt/pos_config.yaml -p $processes -s $step
}

function opensearch_steps() {
     uv_run open_search_prep_all 300 \
  && uv_run open_search_load_all 100 \
  && uv_run open_search_stop \
  && uv_run open_search_disk_snapshot
}

function clickhouse_steps() {
     uv_run clickhouse_load_all \
  && uv_run clickhouse_stop \
  && uv_run clickhouse_disk_snapshot
}

# Main script

install_packages
mount_disk ${OPENSEARCH_DISK_NAME} /mnt/opensearch 
mount_disk ${CLICKHOUSE_DISK_NAME} /mnt/clickhouse
opensearch_steps & clickhouse_steps
if [[ ${OPENSEARCH_TARBALL} == true ]]; then
    uv_run open_search_tarball
fi
if [[ ${CLICKHOUSE_TARBALL} == true ]]; then
    uv_run clickhouse_tarball
fi
poweroff
