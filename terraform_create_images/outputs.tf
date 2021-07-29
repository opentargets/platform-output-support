output "elasticsearch_hostname" {
  value = module.backend_elastic_search.*
}

output "clickhouse_hostname" {
  value = module.backend_clickhouse.*
}

output "pos_support_vm_name" {
  value = module.backend_pos_vm.pos_support_vm_name
}
