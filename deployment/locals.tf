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
  # If this is a partner preview pipeline, do not provide an FTP location.
  ftp_output_path = var.is_ppp == false ? "${var.ftp_location}/${var.release_id}/output/" : ""
  gcs_output_path = "${var.data_location_production}/output/"
  yaml_config_variables = {
        LOG_LEVEL                     = var.pos_log_level
        RELEASE_URI                   = var.data_location_source
        RELEASE                       = var.release_id
        PRODUCT                       = var.is_ppp == false ? "platform" : "ppp"
        RELEASE_FTP_OUTPUT            = local.ftp_output_path
        RELEASE_GCS_OUTPUT            = local.gcs_output_path
        OPENSEARCH_VERSION            = var.open_search_image_tag
        OPENSEARCH_JAVA_OPTS          = var.open_search_jvm_options
        OPENSEARCH_DISK_NAME          = google_compute_disk.open_search_data_disk.name
        OPENSEARCH_DISK_SNAPSHOT_NAME = "${google_compute_disk.open_search_data_disk.name}"
        OPENSEARCH_SNAPSHOT_NAME       = "${var.release_id}-${local.timestamp}"
        OPENSEARCH_SNAPSHOT_REPOSITORY = var.open_search_snapshot_repository
        OPENSEARCH_SNAPSHOT_BUCKET     = var.open_search_snapshot_bucket
        OPENSEARCH_SNAPSHOT_BASE_PATH  = var.open_search_snapshot_base_path
        CLICKHOUSE_VERSION            = var.clickhouse_image_tag
        DATABASE_NAMESPACE            = var.database_namespace
        CLICKHOUSE_DISK_NAME          = google_compute_disk.clickhouse_data_disk.name
        CLICKHOUSE_DISK_SNAPSHOT_NAME = "${google_compute_disk.clickhouse_data_disk.name}"
        CLICKHOUSE_BACKUP_BASE_PATH   = var.clickhouse_backup_base_path
        BQ_DATA_SOURCE                = var.data_location_production
        # For templating reasons, we need to substitute the following variables with $${var_name}
        release                       = "$${release}"
        data_source                   = "$${data_source}"
        local_data                    = "$${local_data}"
        release_ftp_output            = "$${release_ftp_output}"
        release_gcs_output            = "$${release_gcs_output}"
        posvm_remote_user_name        = "$${posvm_remote_user_name}"
        prepared_data                 = "$${prepared_data}"
        opensearch_version            = "$${opensearch_version}"
        opensearch_java_opts          = "$${opensearch_java_opts}"
        opensearch_data               = "$${opensearch_data}"
        opensearch_logs               = "$${opensearch_logs}"
        opensearch_disk_name          = "$${opensearch_disk_name}"
        opensearch_disk_snapshot_name = "$${opensearch_disk_snapshot_name}"
        opensearch_snapshot_name      = "$${opensearch_snapshot_name}"
        opensearch_snapshot_repository = "$${opensearch_snapshot_repository}"
        opensearch_snapshot_bucket     = "$${opensearch_snapshot_bucket}"
        opensearch_snapshot_base_path  = "$${opensearch_snapshot_base_path}"
        clickhouse_version            = "$${clickhouse_version}"
        database_namespace            = "$${database_namespace}"
        clickhouse_data               = "$${clickhouse_data}"
        clickhouse_logs               = "$${clickhouse_logs}"
        clickhouse_disk_name          = "$${clickhouse_disk_name}"
        clickhouse_disk_snapshot_name = "$${clickhouse_disk_snapshot_name}"
        clickhouse_backup_base_path   = "$${clickhouse_backup_base_path}"
        gcs_hmac_file                 = "$${gcs_hmac_file}"
        bq_prod_project_id            = "$${bq_prod_project_id}"
        bq_parquet_path               = "$${bq_parquet_path}"
        each                          = "$${each}"
      }
}