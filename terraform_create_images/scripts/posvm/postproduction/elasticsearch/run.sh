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
  mkdir -p ${pos_es_vol_path_data} ${pos_es_vol_path_json}
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
  # Get machine available memory (KiB)
  export MACHINE_SIZE=`cat /proc/meminfo | grep MemTotal | grep -o '[0-9]\+'`
  # Use all the machine memory for the JVM minus 1GiB
  export JVM_SIZE=`expr $(expr $MACHINE_SIZE / 1048576) - 1`
  export JVM_SIZE_HALF=`expr $MACHINE_SIZE / 2097152`
  log "[INFO] Elastic Search docker container name: ${pos_es_docker_container_name}, cluster name: ${pos_es_cluster_name}, data volume: ${pos_es_vol_path_data}, data load logs at ${pos_path_logs_elastic_search}, JVM size: ${JVM_SIZE}GiB, JVM size half: ${JVM_SIZE_HALF}GiB"
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
    -e ES_JAVA_OPTS="-Xms${JVM_SIZE_HALF}g -Xmx${JVM_SIZE_HALF}g" \
    -e "thread_pool.write.queue_size=-1" \
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
  log "[START][${index_name}] Loading data into Elastic Search for input_folder=${input_folder_name}, index_name=${index_name}, id=${id}, index_settings=${index_settings}, path_to_index_settings='${path_to_index_settings}'"
  # Create index
  log "[INFO][${index_name}] Creating index"
  curl -XPUT -H 'Content-Type: application/json' --data @"${path_to_index_settings}" http://localhost:9200/${index_name}
  log "[INFO][${index_name}] Data source at '${input_folder}'"
  # Iterate over all .parquet files in the input folder and load them into the created index
  # When an ID has been provided, we can re-try loading the data into the given elastic search index, otherwise we can't, as it would create duplicates
  if [[ -n "$id" ]]; then
    max_retries=7
  else
    max_retries=1
  fi
  # Iterate over all parquet files, and json (just maintained fo "so")
  for file in $(gsutil list "${input_folder}/**parquet" "${input_folder}/*json"); do
    if [[ -n "$id" ]]; then
      for ((i = 1; i <= max_retries; i++)); do
        log "[INFO][${index_name}] Loading data file '${file}' with id '${id}' - Attempt #$i"
        parquet_to_json $file | esbulk -index "${index_name}" -type _doc -server http://localhost:9200 -id "${id}" && break || log "[ERROR][${index_name}] Loading data file '${file}' with id '${id}' - FAILED Attempt #$i, retrying..."
        #sleep 1
      done
      if [ $i -gt $max_retries ]; then
        log "[ERROR][${index_name}] Loading data file '${file}' with id '${id}' - ALL ATTEMPTS FAILED."
        return 1
      fi
    else
      for ((i = 1; i <= max_retries; i++)); do
        log "[INFO][${index_name}] Loading data file '${file}' WITHOUT id - Attempt #$i"
        parquet_to_json $file | esbulk -index "${index_name}" -type _doc -server http://localhost:9200 && break || log "[ERROR][${index_name}] Loading data file '${file}' WITHOUT id - FAILED Attempt #$i, retrying..."
        #sleep 1
      done
      if [ $i -gt $max_retries ]; then
        log "[ERROR][${index_name}] Loading data file '${file}' WITHOUT id - ALL ATTEMPTS FAILED."
        return 1
      fi
    fi
  done
  log "[DONE][${index_name}] Loading data into Elastic Search for input_folder=${input_folder_name}, index_name=${index_name}, id=${id}, index_settings=${index_settings}"
  # Report whether the data load was successful or not for the given index
  return 0
}

function cp_json_to_bucket() {
  json_file=$1
  index_dir=$2
  filename=$(basename "${json_file}")
  log "[INFO] copying ${json_file} to ${pos_data_release_path_etl_json}/${index_dir}/${filename}"
  gsutil cp "${json_file}" "${pos_data_release_path_etl_json}${index_dir}/${filename}"
  log "[INFO] cleaning ${json_file}"
  rm -f "${json_file}"
}

function parquet_to_json() {
  parquet_path=$1
  # Have to maintain this for "so" which is a json file
  if [[ "${parquet_path}" == *".json" ]]; then
    gsutil cat "${parquet_path}"
  else
    docker run --rm p2j "${parquet_path}"
  fi
}


function cleanup {
  for index_name in "${!job_status_temp[@]}"; do
    rm -f ${job_status_temp["$index_name"]}
    rm -f ${job_retries_temp["$index_name"]}
  done
}

# Parallel data load implementation given job_status, job_retries, job_param_input_folder, job_param_index_settings and job_param_id details
function do_load_etl_data_into_es_parallel() {
  job_status=$1
  job_retries=$2
  job_param_input_folder=$3
  job_param_index_settings=$4
  job_param_id=$5

  # Array of status and retries files per index
  declare -A job_status_temp
  declare -A job_retries_temp

  trap cleanup EXIT  # Setup the trap to cleanup the temp files on exit

  for index_name in "${!job_status[@]}"; do
    job_status_temp["$index_name"]=$(mktemp -p ${pos_path_tmp})
    job_retries_temp["$index_name"]=$(mktemp -p ${pos_path_tmp})
    status_value=${job_status["$index_name"]}
    retries_value=${job_retries["$index_name"]}
    status_file_name=${job_status_temp["$index_name"]}
    retries_file_name=${job_retries_temp["$index_name"]}
    echo -e "$status_value" > $status_file_name
    echo -e "$retries_value" > $retries_file_name
    log "[INFO] Initialize job status for index '${index_name}' to '" ${job_status["$index_name"]} "' in file '" ${job_status_temp["$index_name"]} "' file content ---> $(cat ${status_file_name})"
    log "[INFO] Initialize job retries for index '${index_name}' to '" ${job_retries["$index_name"]} "' in file '" ${job_retries_temp["$index_name"]} "' file content ---> $(cat ${retries_file_name})"
  done

  # Parallelize the ingestion of the ETL data into Elastic Search by running each job in a separate process per index
  while true; do
    all_jobs_done=true

    for index_name in "${!job_status_temp[@]}"; do
      status_file_name=${job_status_temp["$index_name"]}
      retries_file_name=${job_retries_temp["$index_name"]}
      job_status_value=$(<${status_file_name})
      job_retries_value=$(<${retries_file_name})
      log "[INFO] Job status for index '${index_name}' is '${job_status_value}' in file '${status_file_name}' file content ---> $(cat ${status_file_name})"
      if [ ${job_status_value} -ne 0 ] && [ ${job_retries_value} -lt $max_retries ]; then
        all_jobs_done=false
        (
          load_data_into_es_index ${job_param_input_folder["$index_name"]} ${index_name} ${job_param_index_settings["$index_name"]} ${job_param_id["$index_name"]}
          job_exit_status=$?
          if [ $job_exit_status -eq 0 ]; then
            echo -e "0" > ${status_file_name}
            log "Job for index $index_name completed successfully."
          else
            echo -e "$(($job_retries_value + 1))" > ${retries_file_name}
            log "Job for index $index_name failed. Retrying (attempt $(($job_retries_value + 1)) of $max_retries)..."
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

  # Cleanup the status and retries files per index
  for index_name in "${!job_status_temp[@]}"; do
    rm ${job_status_temp["$index_name"]}
    rm ${job_retries_temp["$index_name"]}
  done
}

# Iterate over the ETL ingestion configuration file and load data into Elastic Search
function load_etl_data_into_es() {
  declare -A job_status
  declare -A job_retries
  declare -A job_param_input_folder
  declare -A job_param_index_settings
  declare -A job_param_id
  max_retries=3

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
      log "[INFO] Initializing job status and retry count for index_name=${index_name}"
      job_status["$index_name"]=1
      if [[ -n "$id" ]]; then
        # We have ID, so we can retry this dataset
        log "[INFO][${index_name}] ENABLED RETRY - max_retries=${max_retries}"
        job_retries["$index_name"]=0
      else
        # We don't have ID, so we can't retry this dataset
        log "[INFO][${index_name}] DISABLED RETRY - max_retries=1 (no ID provided)"
        job_retries["$index_name"]=$((max_retries - 1))
      fi
      job_retries["$index_name"]=0
      job_param_input_folder["$index_name"]="${pos_data_release_path_etl_parquet}/${input_folder}"
      job_param_index_settings["$index_name"]=${index_settings}
      job_param_id["$index_name"]=${id}
  done < "${pos_es_path_etl_ingestion_config}"

  # Add the jobs for loading Evidence data into Elastic Search
  for evidence_path in $( gsutil ls ${pos_data_release_path_etl_parquet}/output/evidence | grep sourceId ); do
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
      log "[INFO] Using custom index settings for index_name=${index_name}, index settings '${pos_es_index_settings_genetics_evidence}'"
      job_param_index_settings["$index_name"]=${pos_es_index_settings_genetics_evidence}
    else
      log "[INFO] Using default index settings for index_name=${index_name}, index settings '${pos_es_default_index_settings}'"
      job_param_index_settings["$index_name"]=${pos_es_default_index_settings}
    fi
    job_param_id["$index_name"]=${pos_es_default_id}
  done

  # Add SO data to Elastic Search
  job_status["${pos_es_so_index_name}"]=1
  job_retries["${pos_es_so_index_name}"]=0
  job_param_input_folder["${pos_es_so_index_name}"]=$( dirname ${pos_es_path_so_file})
  job_param_index_settings["${pos_es_so_index_name}"]=${pos_es_default_index_settings}
  job_param_id["${pos_es_so_index_name}"]=${pos_es_default_id}

  # Run data load jobs in parallel
  do_load_etl_data_into_es_parallel job_status job_retries job_param_input_folder job_param_index_settings job_param_id
}

# Print a summary that shows all the indexes in Elastic Search and their details
function print_es_summary() {
  log "[INFO] Printing Elastic Search summary"
  curl -X GET "localhost:9200/_cat/indices?pretty&s=i"
}

# Stop the running Elastic Search docker container
function stop_elasticsearch() {
  log "[START] Stopping Elastic Search docker container, '${pos_es_docker_container_name}'"
  docker stop ${pos_es_docker_container_name}
  log "[DONE] Stopping Elastic Search docker container, '${pos_es_docker_container_name}'"
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
# Print Elastic Search summary
print_es_summary
# Stop Elastic Search
stop_elasticsearch
