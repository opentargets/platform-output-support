// POS VM name
output "pos_support_vm_name" {
  value = module.backend_pos_vm.pos_support_vm_name
}

// Clickhouse disk image name
output "disk_image_name_clickhouse" {
 value = local.image_name_clickhouse 
}
// ElasticSearch disk image name
output "disk_image_name_elastic_search" {
 value = local.image_name_elastic_search 
}
