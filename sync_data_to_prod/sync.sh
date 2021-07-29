#!/bin/bash

version_tag=${RELEASE_ID}
underscore_version_tag=${version_tag//[\.]/_}
path_prefix="gs://${GS_ETL_DATASET}/"

echo "siamoo qui"
echo $path_prefix
#tmux new -d 'gsutil -m cp -r $path_prefix gs://ot-team/cinzia/test2/'
tmux new-session -d -s gscopy1
tmux send-keys "echo ${path_prefix}" C-m
tmux send-keys "gsutil -m cp -r ${path_prefix} gs://ot-team/cinzia/test2/" C-m

tmux
sudo -u otftpuser CLOUDSDK_PYTHON=/ebi/ftp/private/otftpuser/anaconda3/bin/python /nfs/ftp/private/otftpuser/google-cloud-sdk/bin/gsutil rsync -r gs://open-targets-data-releases/21.06/input/annotation-files/ .
