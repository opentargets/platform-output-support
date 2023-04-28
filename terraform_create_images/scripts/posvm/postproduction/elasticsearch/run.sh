#!/bin/bash

# This script starts the postprocessing pipeline for loading data into Elastic Search

# Helper functions
# Prepare Elastic Search Storage Volume
function prepare_elasticsearch_storage_volume() {
  log "[START] Preparing Elastic Search Storage Volume"
  # Create Elastic Search Storage Volume folders
  mkdir -p ${pos_es_vol_path_data}
  log "[DONE] Preparing Elastic Search Storage Volume"
}

# Run Elastic Search via Docker
function run_elasticsearch() {
  log "[START] Running Elastic Search via Docker, using image ${pos_es_docker_image}"
  local pos_es_cluster_name=`hostname`
  docker run --rm -d \
    --name ${pos_es_docker_container_name} \
    -p 9200:9200 \
    -p 9300:9300 \
    -e path.data=/usr/share/elasticsearch/data \
    -e path.logs=/usr/share/elasticsearch/logs \
    -e cluster.name=${pos_es_cluster_name} \
    -e network.host=0.0.0.0 \
    -e discovery.type=single-node \
    -e bootstrap.memory_lock=true \
    -e search.max_open_scroll_context=5000 \
    -v ${pos_es_vol_path_data}:/usr/share/elasticsearch/data \
    -v ${pos_path_logs_elastic_search}:/usr/share/elasticsearch/logs \
    --ulimit memlock=-1:-1 \
    --ulimit nofile=65536:65536 \
    ${pos_es_docker_image}
}

# Wait for Elastic Search to be ready
function wait_for_elasticsearch() {
  log "[INFO] Waiting for Elastic Search to be ready"
  while ! curl -s http://localhost:9200/_cluster/health?pretty | grep -q '"status" : "green"'; do
    sleep 1
  done
  log "[INFO] Elastic Search is ready"
}
