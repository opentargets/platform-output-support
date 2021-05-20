locals {
  // Ports
  // API Communication Ports
  otp_api_port = 8080
  otp_api_port_name = "otpapiport"

  // VM Settings ---
  vm_machine_type = "custom-${var.vm_graphql_vcpus}-${var.vm_graphql_mem}"
}
