variable "credentials_file"{
    description = "Path to the GCP service account key file"
    type = string
    default = ""
}

variable "project_id" {
  type = string
  default = ""
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}
