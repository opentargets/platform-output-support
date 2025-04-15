ARG TAG=latest

FROM clickhouse/clickhouse-server:${TAG}

ARG UID=1000
ARG GID=1000

USER root

RUN chown -R ${UID}:${GID} /var/lib/clickhouse /var/log/clickhouse-server /etc/clickhouse-server /docker-entrypoint-initdb.d 

USER ${UID}:${GID}