provider "google" {
    credentials = file("gcp_project/credentials.json")
    project = file("gcp_project/project_id.txt")
    region = var.region
    zone = var.zone
}
