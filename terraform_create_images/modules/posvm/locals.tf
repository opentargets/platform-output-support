locals {
  roles   = ["roles/compute.admin", "roles/logging.viewer","roles/compute.instanceAdmin","roles/storage.objectViewer","roles/storage.admin"]
  remote_user_name = "provisioner"
}