include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/tf/modules/gcp-public-microk8s-vm"
}

locals {
  admin_vars = yamldecode(file(find_in_parent_folders("admin_vars.yaml")))
}

inputs = {
  project_id          = "spiritofbrogan"
  region              = "us-west1"
  vm_name             = "vm-spiritofbrogan"
  vm_zone             = "us-west1-a"
  vm_machine_type     = "e2-medium"
  vm_image            = "ubuntu-os-cloud/ubuntu-2204-lts"
  boot_disk_size      = "36"
  vm_ssh_key_path     = "${get_repo_root()}/keys/devops_user_pkcs8.pub"
  admin_source_ranges = local.admin_vars.source_ranges # Reference a hidden file for admin IPs.
}