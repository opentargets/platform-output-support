locals {
  // Ports
  elastic_search_port_requests  = 9200
  elastic_search_port_comms     = 9300
  elastic_search_port_requests_name = "esportrequests"
  elastic_search_port_comms_name = "esportcomms"
  // VM Settings ---
  vm_machine_type = "custom-${var.vm_elastic_search_vcpus}-${var.vm_elastic_search_mem}-ext"

}
