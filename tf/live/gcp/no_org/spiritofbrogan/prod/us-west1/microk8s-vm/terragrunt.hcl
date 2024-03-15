include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/tf/modules/gcp-public-microk8s-vm"
}

locals {
  admin_vars = yamldecode(file(find_in_parent_folders("admin_vars.yaml")))

  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region_name = local.region_vars.locals.region_name
  
  project_vars = read_terragrunt_config(find_in_parent_folders("project.hcl"))
  project_id = local.project_vars.locals.project_id
}

inputs = {
  project_id          = local.project_id
  region              = local.region_name
  vm_name             = "vm-${local.project_id}"
  vm_zone             = "${local.region_name}-a"
  vm_machine_type     = "e2-medium"
  vm_image            = "ubuntu-os-cloud/ubuntu-2204-lts"
  boot_disk_size      = "36"
  vm_ssh_key_path     = "${get_repo_root()}/keys/devops_user_pkcs8.pub"
  admin_source_ranges = local.admin_vars.source_ranges # Reference a hidden file for admin IPs.
}