locals {
  // Ports
  clickhouse_http_req_port = 8123
  clickhouse_cli_req_port = 9000
  clickhouse_http_req_port_name  = "portclickhousehttp"
  clickhouse_cli_req_port_name = "portclickhousereq"

  // VM Settings ---
  vm_machine_type = "custom-${var.vm_clickhouse_vcpus}-${var.vm_clickhouse_mem}"
}
