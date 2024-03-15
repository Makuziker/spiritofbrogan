provider "google" {
  project = var.project_id
  region  = var.region
}

# resource "google_project" "this" {
#   name       = var.project_id
#   project_id = var.project_id
#   org_id     = var.org_id
# }

# Optional: create a google_compute_network to use instead of "default"

resource "google_compute_instance" "this" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.vm_zone

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.boot_disk_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    ssh-keys = "${var.vm_ssh_user}:${file("${var.vm_ssh_key_path}")}"
  }

  tags = [var.vm_name]
}

resource "google_compute_firewall" "https" {
  name    = "firewall-microk8s-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.vm_name}"]
}

resource "google_compute_firewall" "admin" {
  name    = "firewall-microk8s-admin"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "16443"]
  }

  source_ranges = var.admin_source_ranges
  target_tags   = ["${var.vm_name}"]
}
