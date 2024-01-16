provider "google" {
    # credentials = file("${abspath(path.root)}\\gcp_project\\credentials.json")
    # project = file("${abspath(path.root)}\\gcp_project\\project_id.txt")
    credentials = file("gcp_project/credentials.json")
    project = file("gcp_project/project_id.txt")
    region = var.region
    zone = var.zone
}
