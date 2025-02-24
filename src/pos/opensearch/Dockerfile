FROM opensearchproject/opensearch:2.19.0

# Install GCS snapshot repo plugin
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch repository-gcs

# Remove query-insights plugin
RUN /usr/share/opensearch/bin/opensearch-plugin remove query-insights