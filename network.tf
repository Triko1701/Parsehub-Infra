
resource "google_compute_address" "main" {
  for_each = local.VMs_details
  name = each.key
  description = "Static IP address for the VMs"
}

data "google_compute_address" "main" {
  for_each = google_compute_address.main
  name   = each.key
}

resource "google_compute_firewall" "main" {
  for_each = local.VMs_details
  name = each.key
  allow {
    ports    = each.value.ports
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = "default"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = each.value.network_tag
}