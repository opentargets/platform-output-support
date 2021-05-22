output "pos_support_vm_name" {
  value = join("",google_compute_instance.pos_vm.*.name)
}

output "test" {
  value = google_compute_instance.pos_vm.*.self_link
}

output "test2" {
  value = google_compute_instance.pos_vm.*
}