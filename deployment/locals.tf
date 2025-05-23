locals {
  posvm_remote_user_name = "otops"
  timestamp              = formatdate("YYYYMMDD-hhmm", timestamp())
  open_search_disk_name  = "pos-${local.timestamp}-os"
  clickhouse_disk_name   = "pos-${local.timestamp}-ch"
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
  yaml_config_variables = {
        LOG_LEVEL                     = var.pos_log_level
        RELEASE_URI                   = var.data_location_source
        RELEASE                       = var.platform_release_version
        OPENSEARCH_VERSION            = var.open_search_image_tag
        OPENSEARCH_JAVA_OPTS          = var.open_search_jvm_options
        OPENSEARCH_DISK_NAME          = google_compute_disk.open_search_data_disk.name
        OPENSEARCH_DISK_SNAPSHOT_NAME = "${google_compute_disk.open_search_data_disk.name}-snapshot"
        CLICKHOUSE_VERSION            = var.clickhouse_image_tag
        CLICKHOUSE_DISK_NAME          = google_compute_disk.clickhouse_data_disk.name
        CLICKHOUSE_DISK_SNAPSHOT_NAME = "${google_compute_disk.clickhouse_data_disk.name}-snapshot"
        BQ_DATA_SOURCE                = var.data_location_production
        # For templating reasons, we need to substitute the following variables with $${var_name}
        release                       = "$${release}"
        data_source                   = "$${data_source}"
        local_data                    = "$${local_data}"
        prepared_data                 = "$${prepared_data}"
        opensearch_version            = "$${opensearch_version}"
        opensearch_java_opts          = "$${opensearch_java_opts}"
        opensearch_data               = "$${opensearch_data}"
        opensearch_logs               = "$${opensearch_logs}"
        opensearch_disk_name          = "$${opensearch_disk_name}"
        opensearch_disk_snapshot_name = "$${opensearch_disk_snapshot_name}"
        clickhouse_version            = "$${clickhouse_version}"
        clickhouse_data               = "$${clickhouse_data}"
        clickhouse_logs               = "$${clickhouse_logs}"
        clickhouse_disk_name          = "$${clickhouse_disk_name}"
        clickhouse_disk_snapshot_name = "$${clickhouse_disk_snapshot_name}"
        bq_prod_project_id            = "$${bq_prod_project_id}"
        bq_parquet_path               = "$${bq_parquet_path}"
        each                          = "$${each}"
      }
}