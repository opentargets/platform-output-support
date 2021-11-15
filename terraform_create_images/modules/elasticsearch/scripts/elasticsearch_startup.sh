#!/bin/bash
# Startup script for Elastic Search VM Instance

echo "---> [LAUNCH] Open Targets Platform Elastic Search"

echo "create a temporary location to put temporary files into"
mkdir -p /tmp

docker volume create esdata

#copy the service account credentials into the VM
mkdir -p /var/elasticsearch/log/

# 1024*1024 = bytes -> gigabytes
# 2 = we want half the total
# 1024*1024*2 = 2097152
# Get machine available memory
export MACHINE_SIZE=`cat /proc/meminfo | grep MemTotal | grep -o '[0-9]\+'`
# Set half the available RAM for the JVM
export JVM_SIZE=`expr $MACHINE_SIZE / 2097152`

echo "JVM_SIZE: " $JVM_SIZE
echo "-Xms$${JVM_SIZE}g -Xmx$${JVM_SIZE}g"

#start elasticsearch
#-----------------------

#configure elasticseach
#  cluster.name            must be unique on network for udp broadcast
#  network.host            allow connections on any network device, not just localhost
#  http.port               use only 9200 nothing else
#  bootstrap.memory_lock   disable swap
#  xpack.security.enabled  turn off xpack extras
#  search.max_open_scroll_context
#                          increase nuber of scrolls possible at once
#  discovery.type          turn off clustering
#  thread_pool.write.queue_size
#    size of the queue for bulk indexing tasks
#      needed for high submissions from pipeline

docker run -d --restart always \
  --name elasticsearch \
  -p 9200:9200 \
  -p 9300:9300 \
  -e discovery.type=single-node \
  -e bootstrap.memory_lock=true \
  -e repositories.url.allowed_urls='https://storage.googleapis.com/*,https://*.amazonaws.com/*' \
  -e thread_pool.write.queue_size=1000 \
  -e cluster.name=`hostname` \
  -e network.host=0.0.0.0 \
  -e search.max_open_scroll_context=5000 \
  -e ES_JAVA_OPTS="-Xms$${JVM_SIZE}g -Xmx$${JVM_SIZE}g" \
  -v esdata:/usr/share/elasticsearch/data \
  -v /var/elasticsearch/log:/var/log/elasticsearch \
   docker.elastic.co/elasticsearch/elasticsearch-oss:${ELASTIC_SEARCH_VERSION}

POLL=1
echo "POLL="$POLL
while [ $POLL != "0" ]
 do
  sleep 10
  #allow non zero exit codes since that is what we are checking for
  set +e
  # elasticsearch script will wait until the ES server is up.
  # The creation of the snapshot will fail if the server is not up and running.
  curl -X GET "http://localhost:9200/_cluster/health?wait_for_status=green"
  POLL=$?
  echo "POLL="$POLL
  #disallow non zero exit codes again since that is sensible
  set -e
done

kibana_deb=https://artifacts.elastic.co/downloads/kibana/kibana-${ELASTIC_SEARCH_VERSION}-amd64.deb


echo "---> [LAUNCH] Open Targets Platform Elastic Kibana"
docker run -d \
 --name kibana \
 -p 5601:5601 \
 --restart unless-stopped \
 --link elasticsearch:elasticsearch \
 -e "ELASTICSEARCH_URL=http://elasticsearch:9200" \
 docker.elastic.co/kibana/kibana-oss:${ELASTIC_SEARCH_VERSION}

