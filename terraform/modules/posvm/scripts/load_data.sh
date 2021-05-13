#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] POS support VM"

sudo apt update && sudo apt -y install python3-pip
sudo pip3 install elasticsearch-loader


echo "test cinzia"
echo $ELASTICSEARCH_URI

echo $$ELASTICSEARCH_URI
echo $strin
