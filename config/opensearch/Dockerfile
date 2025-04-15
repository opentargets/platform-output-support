ARG TAG=latest

FROM opensearchproject/opensearch:${TAG}

ARG UID=1000
ARG GID=1000

USER root

# Remove query-insights plugin
RUN /usr/share/opensearch/bin/opensearch-plugin remove query-insights

RUN chown -R ${UID}:${GID} /usr/share/opensearch

USER ${UID}:${GID}