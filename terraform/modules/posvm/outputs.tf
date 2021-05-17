output "pos_support_vm_name" {
  value = join("",google_compute_instance.pos_vm.*.name)
}
