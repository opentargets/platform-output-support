output "graphql_vm_name" {
  value =join("", google_compute_instance.graphql_instance.*.name)
}
