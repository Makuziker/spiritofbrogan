remote_state {
  // Disable the initialization of a backend. Use local state by default.
  // Incomplete
  disable_init = true
}

terraform {
  source = "${get_repo_root()}/tf/modules/gcp-public-microk8s-vm"
}

inputs = {
  project_id      = "spiritofbrogan"
  region          = "us-west1"
  vm_name         = "vm-spiritofbrogan"
  vm_zone         = "us-west1-a"
  vm_machine_type = "e2.medium"
  vm_image        = "ubuntu-os-cloud/ubuntu-2204-lts"
  boot_disk_size  = "36"
  vm_ssh_key_path = "${get_repo_root()}/keys/devops_user.pub"
}