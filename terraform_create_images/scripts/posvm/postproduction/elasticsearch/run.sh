#!/bin/bash

# This script starts the postprocessing pipeline for loading data into Elastic Search

# Bootstrapping environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load local configuration
source ${SCRIPTDIR}/config.sh

# Helper functions
# Prepare Elastic Search Storage Volume
function prepare_elasticsearch_storage_volume() {
  log "[START] Preparing Elastic Search Storage Volume"
  # Create Elastic Search Storage Volume folders
  mkdir -p ${pos_es_vol_path_data}
  # Create a docker volume that points to the Elastic Search Storage Volume data folder
  docker volume create --name ${pos_es_docker_vol_data} --opt type=none --opt device=${pos_es_vol_path_data} --opt o=bind
  docker volume create --name ${pos_es_docker_vol_logs} --opt type=none --opt device=${pos_path_logs_elastic_search} --opt o=bind
  log "[DONE] Preparing Elastic Search Storage Volume"
}

# Run Elastic Search via Docker
function run_elasticsearch() {
  log "[START] Running Elastic Search via Docker, using image ${pos_es_docker_image}"
  log "[INFO] Setting vm.max_map_count to 262144"
  sysctl -w vm.max_map_count=262144
  log "[INFO] Elastic Search docker container name: ${pos_es_docker_container_name}, cluster name: ${pos_es_cluster_name}, data volume: ${pos_es_vol_path_data}, data load logs at ${pos_path_logs_elastic_search}"
  local pos_es_cluster_name=`hostname`
  docker run --rm -d \
    --name ${pos_es_docker_container_name} \
    -p 9200:9200 \
    -p 9300:9300 \
    -e "path.data=/usr/share/elasticsearch/data" \
    -e "path.logs=/usr/share/elasticsearch/logs" \
    -e "cluster.name=${pos_es_cluster_name}" \
    -e "network.host=0.0.0.0" \
    -e "discovery.type=single-node" \
    -e "discovery.seed_hosts=[]" \
    -e "bootstrap.memory_lock=true" \
    -e "search.max_open_scroll_context=5000" \
    -v ${pos_es_docker_vol_data}:/usr/share/elasticsearch/data \
    -v ${pos_es_docker_vol_logs}:/usr/share/elasticsearch/logs \
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

# Load data into Elastic Search for a given input_folder, index_name, id and index_settings
function load_data_into_es_index() {
  local input_folder=$1
  local index_name=$2
  local index_settings=$3
  local id=$4
  local path_to_index_settings="${pos_es_path_index_settings}/${index_settings}"
  local input_folder_name=$(basename ${input_folder})
  log "[START][${index_name}] Loading data into Elastic Search for input_folder=${input_folder_name}, index_name=${index_name}, id=${id}, index_settings=${index_settings}"
  # Create index
  log "[INFO][${index_name}] Creating index"
  curl -X PUT "localhost:9200/${index_name}?pretty" -H 'Content-Type: application/json' -d"${path_to_index_settings}"
  log "[INFO][${index_name}] Data source at '${input_folder}'"
  # Iterate over all .json files in the input folder and load them into the created index
  max_retries=12
  for file in $(gsutil list ${input_folder}/*.json); do
    if [[ -n "$id" ]]; then
      #log "[INFO][${index_name}] Loading data file '${file}' with id '${id}'"
      for ((i = 1; i <= max_retries; i++)); do
        log "[INFO][${index_name}] Loading data file '${file}' with id '${id}' - Attempt #$i"
        gsutil cp "${file}" - | esbulk -size 2000 -w 8 -index "${index_name}" -type _doc -server http://localhost:9200 -id "${id}" && break || log "[ERROR][${index_name}] Loading data file '${file}' with id '${id}' - FAILED Attempt #$i, retrying..."
        sleep 1
      done
      #gsutil cp ${file} - | esbulk -size 2000 -w 8 -index ${index_name} -type _doc -server http://localhost:9200 -id ${id} 
    else
      #log "[INFO][${index_name}] Loading data file '${file}' WITHOUT id"
      for ((i = 1; i <= max_retries; i++)); do
        log "[INFO][${index_name}] Loading data file '${file}' WITHOUT id - Attempt #$i"
        gsutil cp ${file} - | esbulk -size 2000 -w 8 -index ${index_name} -type _doc -server http://localhost:9200 && break || log "[ERROR][${index_name}] Loading data file '${file}' WITHOUT id - FAILED Attempt #$i, retrying..."
        sleep 1
      done
      #gsutil cp ${file} - | esbulk -size 2000 -w 8 -index ${index_name} -type _doc -server http://localhost:9200
    fi
  done
  log "[DONE][${index_name}] Loading data into Elastic Search for input_folder=${input_folder_name}, index_name=${index_name}, id=${id}, index_settings=${index_settings}"
}

# Iterate over the ETL ingestion configuration file and load data into Elastic Search
function load_etl_data_into_es() {
  local max_retries=12
  declare -A job_status
  declare -A job_retries
  declare -A job_param_input_folder
  declare -A job_param_index_settings
  declare -A job_param_id

  # Iterate over the ETL ingestion configuration
  while IFS= read -r line
  do
      # Skip lines starting with '#'
      if [[ $line =~ ^# ]]; then
          continue
      fi

      # Process the line as CSV
      IFS=, read -r input_folder index_name id index_settings <<< "$line"

      # Initialize job status and retry count
      job_status["$index_name"]=1
      job_retries["$index_name"]=0
      job_param_input_folder["$index_name"]="${pos_data_release_path_etl_json}/${input_folder}"
      job_param_index_settings["$index_name"]=${index_settings}
      job_param_id["$index_name"]=${id}
  done < "${pos_es_path_etl_ingestion_config}"
  
  # Add the jobs for loading Evidence data into Elastic Search
  for evidence_path in $( gsutil ls ${pos_data_release_path_etl_json}/evidence | grep sourceId ); do
    # Extract the sourceId from the path
    export full_path="${evidence_path%/}"
    export source_id="${full_path##*/}"
    # Compute the relative input folder and index name
    export index_name_suffix="${source_id#*=}"
    export index_name=evidence_datasource_"${index_name_suffix}"
    # Initialize job status and retry count
    job_status["$index_name"]=1
    job_retries["$index_name"]=0
    job_param_input_folder["$index_name"]=${full_path}
    if [[ "${index_name_suffix}" == "ot_genetics_portal" ]]; then
      job_param_index_settings["$index_name"]=${pos_es_index_settings_genetics_evidence}
    else
      job_param_index_settings["$index_name"]=${pos_es_default_index_settings}
    fi
    job_param_id["$index_name"]=${pos_es_default_id}
  done

  # Add SO data to Elastic Search
  job_status["${pos_es_so_index_name}"]=1
  job_retries["${pos_es_so_index_name}"]=0
  job_param_input_folder["${pos_es_so_index_name}"]=${pos_es_path_so_file}
  job_param_index_settings["${pos_es_so_index_name}"]=${pos_es_default_index_settings}
  job_param_id["${pos_es_so_index_name}"]=${pos_es_default_id}
  
  # Parallelize the ingestion of the ETL data into Elastic Search by running each job in a separate process per index
  while true; do
    all_jobs_done=true

    for index_name in "${!job_status[@]}"; do
      if [ ${job_status["$index_name"]} -ne 0 ] && [ ${job_retries["$index_name"]} -lt $max_retries ]; then
        all_jobs_done=false
        (
          load_data_into_es_index ${job_param_input_folder["$index_name"]} ${index_name} ${job_param_index_settings["$index_name"]} ${job_param_id["$index_name"]}
          job_exit_status=$?
          if [ $job_exit_status -eq 0 ]; then
            job_status["$index_name"]=0
            log "Job for index $index_name completed successfully."
          else
            job_retries["$index_name"]=$((job_retries["$index_name"] + 1))
            log "Job for index $index_name failed. Retrying (attempt ${job_retries["$index_name"]} of $max_retries)..."
          fi
        ) &
      fi
    done
    
    # Wait for all background jobs to complete
    wait

    if $all_jobs_done; then
      break
    else
      sleep 1
    fi
  done 
    #load_data_into_es_index ${input_folder} ${index_name} ${index_settings} ${id}
  # TODO - Load SO data into Elastic Search
}


# Main
# Prepare Elastic Search Storage Volume
prepare_elasticsearch_storage_volume
# Run Elastic Search via Docker
run_elasticsearch
# Wait for Elastic Search to be ready
wait_for_elasticsearch
# Load data into Elastic Search
load_etl_data_into_es