#!/bin/bash
echo ${ELASTICSEARCH_URI}
echo ${GS_ETL_DATASET}

#This is a prototype. Change when ETL will be stable in the output approach
export PREFIX=${PREFIX_DATA:-"out"}
export RELEASE=${ETL_RELEASE:-""}
# the default index settings file
export INDEX_SETTINGS=${ETL_INDEX_SETTINGS:-"index_settings.json"}
# default ES endpoint
export ES=${ELASTICSEARCH_URI}:-"http://localhost:9200"}

echo $PREFIX_DATA
echo $ES
echo $INDEX_SETTINGS
echo $PREFIX
echo $RELEASE