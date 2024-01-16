provider "google" {
    credentials = file("${path.module}/sa-keys/credentials.json")
    project = var.project_id
    region = var.region
    zone = var.zone
}
