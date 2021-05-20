output "elasticsearch_hostname" {
  value = module.backend_elastic_search.elasticsearch_vm_name
}

output "clickhouse_hostname" {
  value = module.backend_clickhouse.clickhouse_vm_name
}

output "pos_support_vm_name" {
  value = module.backend_pos_vm.pos_support_vm_name
}

output "graphql_hostame_info" {
  value = module.backend_graphql.*
}