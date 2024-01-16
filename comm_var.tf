variable "credentials_file"{
    description = "Path to the GCP service account key file"
    type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}
