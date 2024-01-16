resource "google_compute_instance" "main" {
  for_each = local.VMs_details

  ###############################
  ##### IMPORTANT ARGUMENTS #####
  ###############################

  name = each.key
  # project = var.project_id
  # zone = var.zone

  machine_type = each.value.machine_type
  metadata = each.value.metadata
  tags = each.value.network_tag
  
  boot_disk {
    device_name = each.key
    initialize_params {
      image = each.value.image
      size  = each.value.size
      type  = each.value.type
    }
  }
  
  network_interface {
    access_config {
      nat_ip = data.google_compute_address.main[each.key].address
    }

    subnetwork = "default"
  }

  service_account {
    email  = var.sa_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  ################################
  ##### ADDITIONAL ARGUMENTS #####
  ################################

  allow_stopping_for_update = true
  can_ip_forward      = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

}