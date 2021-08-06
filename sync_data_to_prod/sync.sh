#!/bin/bash

path_prefix="gs://${GS_SYNC_FROM}/"

ssh noah-login-02 "sudo -u otftpuser mkdir /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}; sudo -u otftpuser chmod 775 /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}"
ssh noah-login-02 "tmux new-session -d -s gscopytoftp"
ssh noah-login-02 "tmux send-keys 'cd /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}; CLOUDSDK_PYTHON=/ebi/ftp/private/otftpuser/anaconda3/bin/python /nfs/ftp/private/otftpuser/google-cloud-sdk/bin/gsutil rsync -r -x ^input/fda-files/* gs://${GS_SYNC_FROM}/ . '  C-m"
ssh noah-login-02 "tmux send-keys 'sudo -u otftpuser mkdir /nfs/ftp/pub/databases/opentargets/platform/${RELEASE_ID_PROD}; '  C-m"
ssh noah-login-02 "tmux send-keys 'sudo -u otftpuser cp -R /nfs/ftp/private/otftpuser/upload/platform/${RELEASE_ID_PROD}/* /nfs/ftp/pub/databases/opentargets/platform/${RELEASE_ID_PROD}'  C-m"
ssh noah-login-02 "tmux send-keys 'sudo -u otftpuser chmod -R 755 /nfs/ftp/pub/databases/opentargets/platform/${RELEASE_ID_PROD}'  C-m"
ssh noah-login-02 "tmux send-keys 'echo "done"'  C-m"
#do not kill the session here!
#ssh noah-login-02 "tmux kill-session -t gscopytoftp"
