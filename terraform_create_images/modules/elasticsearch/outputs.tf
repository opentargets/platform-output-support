output "elasticsearch_vm_name" {
  value =join("", google_compute_instance.elasticsearch_etl.*.name)
}
