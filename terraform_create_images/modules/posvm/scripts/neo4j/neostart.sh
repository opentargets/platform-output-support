#!/bin/bash

log_info() {
  # https://www.howtogeek.com/410442/how-to-display-the-date-and-time-in-the-linux-terminal-and-use-it-in-bash-scripts/
  printf '%s %s\n' "$(date +"%Y-%m-%d %H:%M:%S:%z") INFO  Neo4j load script: $1"
  return
}

set -m

# Start the primary process and put it in the background
/docker-entrypoint.sh neo4j &

# Wait for Neo4j
log_info "Checking to see if Neo4j has started..."
wget --quiet --retry-connrefused --tries --waitretry -O /dev/null http://${DB_HOST}:${DB_PORT}
log_info "Neo4j has started."

# Import data
log_info  "Loading and importing Cypher file(s)..."

for cypherFile in /var/lib/neo4j/import/*.cypher; do
    log_info "Processing ${cypherFile}..."
    cypher-shell -u ${DB_USER} -p ${DB_PASSWORD} --format plain --file ${cypherFile}
done

log_info  "Finished loading data."

# now we bring the primary process back into the foreground
# and leave it there
fg %1