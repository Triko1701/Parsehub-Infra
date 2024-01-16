provider "google" {
    credentials = file("gcp_project/credentials.json")
    project = file("gcp_project/project_id.txt")
    region = file("gcp_project/region.txt")
    zone = file("gcp_project/zone.txt")
}
