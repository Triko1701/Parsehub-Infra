variable "sa_email" {
  description = "Service account email address"
  type = string
  default = "web-scraping@web-scraping-20231227045450030.iam.gserviceaccount.com"
}

variable "master" {
  description = "Master VM details"
  type = object({
    image = string
    size = number
    type = string
    machine_type = string
    network_tag = list(string)
    ports = list(string)
  })
}

variable "slave" {
  description = "Slave VM details"
  type = object({
    image = string
    size = number
    type = string
    machine_type = string
    network_tag = list(string)
    ports = list(string)
  })
}

variable "parsehub_creds"{
  description = "ParseHub API key and project token"
  type = list(object({
    API_KEY = string
    PROJ_TOKEN = string
  }))
}

variable "shared_meta"{
  description = "User, project, and base directory variables"
  type = object({
    BASE_DIR = string
    USER = string
    PROJECT = string
  })
}

variable "GG_SHEET_URL" {
  description = "Google Sheet URL for the scraping project"
  type = string
}
