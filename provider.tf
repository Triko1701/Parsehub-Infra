provider "google" {
    credentials = file("sa-key/credentials.json")
    project = var.project_id
    region = var.region
    zone = var.zone
}
