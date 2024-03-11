variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

# variable "org_id" {
#   type = string
# }

variable "vm_name" {
  type = string
}

variable "vm_zone" {
  type = string
}

variable "vm_machine_type" {
  type = string
}

variable "vm_image" {
  type = string
}

variable "boot_disk_size" {
  type = string
}

variable "vm_ssh_user" {
  type    = string
  default = "devops_user"
}

variable "vm_ssh_key_path" {
  type = string
}

variable "admin_source_ranges" {
  description = "List of IPs to allow SSH and kubectl API access from."
  type        = list(string)
}
