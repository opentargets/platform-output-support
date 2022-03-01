#!/bin/bash

path_prefix="gs://${GS_SYNC_FROM}/"

ssh noah-login-05 "sudo -u otftpuser mkdir /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}; sudo -u otftpuser chmod 755 /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}"
ssh noah-login-05 "tmux new-session -d -s gscopytoftp"
ssh noah-login-05 "tmux send-keys 'cd /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}; CLOUDSDK_PYTHON=/nfs/production/opentargets/anaconda3/bin/python /nfs/production/opentargets/google-cloud-sdk/bin/gsutil -m rsync -r -x ^input/fda-inputs/* gs://${GS_SYNC_FROM}/ . '  C-m"
ssh noah-login-05 "tmux send-keys 'sudo -u otftpuser mkdir /nfs/ftp/pub/databases/opentargets/platform/${RELEASE_ID_PROD}; '  C-m"
ssh noah-login-05 "tmux send-keys 'sudo -u otftpuser rsync -rv /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}/* /nfs/ftp/pub/databases/opentargets/platform/${RELEASE_ID_PROD}'  C-m"
ssh noah-login-05 "tmux send-keys 'cd /nfs/ftp/pub/databases/opentargets/platform/; sudo -u otftpuser find ${RELEASE_ID_PROD} -type d -exec chmod 755 \{} \; ; sudo -u otftpuser find ${RELEASE_ID_PROD} -type f -exec chmod 644 \{} \;'  C-m"
ssh noah-login-05 "tmux send-keys 'cd /ebi/ftp/pub/databases/opentargets/platform'  C-m"
ssh noah-login-05 "tmux send-keys 'sudo -u otftpuser ln -nsf ${RELEASE_ID_PROD} latest'  C-m"
ssh noah-login-05 "tmux send-keys 'echo "done"'  C-m"
#do not kill the session here!
#ssh noah-login-05 "tmux kill-session -t gscopytoftp"
