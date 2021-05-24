output "clickhouse_vm_name" {
  value =join("", google_compute_instance.clickhouse_etl.*.name)
}
