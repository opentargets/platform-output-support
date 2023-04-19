// POS VM name
output "posvm_name" {
  value = google_compute_instance.posvm.name
}

// Clickhouse disk image name
output "disk_image_name_clickhouse" {
  value = local.disk_image_name_clickhouse
}
// ElasticSearch disk image name
output "disk_image_name_elastic_search" {
  value = local.disk_image_name_elastic_search
}
