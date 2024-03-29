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
output "data_disk_images" {
  value = {
    clickhouse     = local.disk_image_name_clickhouse
    elastic_search = local.disk_image_name_elastic_search
  }
  description = "Data disk images names"
}

