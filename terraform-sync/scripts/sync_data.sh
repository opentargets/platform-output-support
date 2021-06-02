#!/bin/bash
#initial setup
#-------------

#create a directory to put configuration into and get dumps out of
#cleanup any old versions
rm -rf /usr/src/rclone
mkdir /usr/src/rclone
mkdir /usr/src/rclone/conf
mkdir /usr/src/rclone/rclone_logs
mkdir /usr/src/rclone/credentials
chmod -R 777 /usr/src/rclone/rclone_logs
echo "sono qui ..."
sudo apt-get -y install tmux
sudo apt-get -y install unzip
sudo apt-get -y install jq
curl https://rclone.org/install.sh | sudo bash

cat > /usr/src/rclone/conf/rclone.conf <<EOF_B
[platform-prod-gs]
type = google cloud storage
service_account_file = /usr/src/rclone/credentials/open-targets-prod.json
location = europe-north1
project_number = 352646847630

[platform-dev-gs]
type = google cloud storage
service_account_file = /usr/src/rclone/credentials/open-targets-eu-dev.json
location = europe-north1
project_number = 426265110888

[platform-open-targets]
type = google cloud storage
service_account_file = /usr/src/rclone/credentials/open-targets-prod.json
location = europe-north1
project_number = 15008602401

[ftp-private-ebi]
type = ftp
host = ftp-private.ebi.ac.uk
user = otftpuser
pass = ${FTP_PASS}
EOF_B


echo ${PROD_SVC} > /usr/src/rclone/credentials/open-targets-prod.json
echo ${EU_DEV_SVC} > /usr/src/rclone/credentials/open-targets-eu-dev.json

LOGFILE="/usr/src/rclone/rclone_logs/rclone-upload.log"
FROM="platform-prod-gs:"${GS_ETL_DATASET}
TO="ftp-private-ebi:upload/platform/"${FTP_DIR}
CONF_FILE="/usr/src/rclone/conf/rclone.conf"

echo $LOGFILE
echo $FROM
echo $TO
echo $CONF_FILE
rclone sync --config=$CONF_FILE $FROM $TO --log-level INFO --log-file $LOGFILE."last"

echo "done"
