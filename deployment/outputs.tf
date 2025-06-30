// POS VM name
output "posvm" {
  value = {
    name = google_compute_instance.posvm.name
    zone = google_compute_instance.posvm.zone
    username = local.posvm_remote_user_name
  }
  description = "POS VM information"
}

// Disk Images
output "disk_snapshots" {
  value = {
    opensearch     = "${local.open_search_disk_name}-snapshot"
    clickhouse     = "${local.clickhouse_disk_name}-snapshot"
  }
  description = "Data disk snapshot names"
}

output "pos_config_file" {
    value = {
      config_file = google_compute_instance.posvm.metadata.pos_config
    }
}

output "pos_log_command" {
  value = {
    command = "gcloud compute ssh --zone ${google_compute_instance.posvm.zone} ${google_compute_instance.posvm.name} --project open-targets-eu-dev --command 'journalctl -u google-startup-scripts.service -f'"
  }
  description = "Command to tail the POS log file"
}

output "pos_logs_gcs" {
  value = {
    logs = "gs://open-targets-ops/logs/platform-pos/${random_string.posvm.result}/pos/"
  }
}