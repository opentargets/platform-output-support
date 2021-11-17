FROM neo4j:4.3.7-community

# authentication
ENV DB_PASSWORD=opentargets
ENV DB_USER=neo4j
ENV DB_HOST=localhost
ENV DB_PORT=7474

ENV NEO4J_AUTH=${DB_USER}/${DB_PASSWORD}

# Data and load script
ENV NEO4J_HOME="/var/lib/neo4j" 
ENV DATA_HOME=./data/
ENV LOAD_SCRIPT=./load.cypher
ENV START_SCRIPT=./neostart.sh

# Neo configuration
ENV NEO4J_dbms_memory_heap_initial__size=5g
ENV NEO4J_dbms_memory_heap_max__size=5g
ENV NEO4J_dbms_memory_pagecache_size=6g

# Intialise DB
COPY ${DATA_HOME} ${NEO4J_HOME}/import/data
COPY ./headers ${NEO4J_HOME}/import/headers

COPY extension_script.sh /extension_script.sh
COPY ${LOAD_SCRIPT} ${NEO4J_HOME}/import/
COPY ${START_SCRIPT} start.sh
RUN chmod +x start.sh

# Tell Neo about existence of extension script
ENV EXTENSION_SCRIPT=/extension_script.sh    

EXPOSE 7474 7473 7687

ENTRYPOINT ["./start.sh"]
