#!/bin/bash

set -x

# Environment variables
flag_startup_completed="/tmp/posvm_startup_complete"

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
    UV_UNMANAGED_INSTALL=$${HOME}/.local/bin
    su ${POS_USER_NAME} -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    git clone https://github.com/opentargets/platform-output-support.git /opt/platform-output-support
    cd /opt/platform-output-support
    git checkout ${BRANCH}
    chgrp -R google-sudoers /opt/platform-output-support
    chmod -R g+rw /opt/platform-output-support
}

# Script completion hook to flag that 'startup script' has already been run
function startup_complete() {
  log "Startup script completed"
  touch $${flag_startup_completed}
}

# Set trap to run 'startup_complete' function on exit
trap startup_complete EXIT

# Check if startup script has already been run
if [[ -f $${flag_startup_completed} ]]; then
  log "Startup script already completed, skipping"
  exit 0
fi


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
  chown -R ${POS_USER_NAME} $${mount_point}
}

# Main script

install_packages
mount_disk ${OPENSEARCH_DISK_NAME} /mnt/opensearch 
mount_disk ${CLICKHOUSE_DISK_NAME} /mnt/clickhouse 

# run the steps
#poweroff
