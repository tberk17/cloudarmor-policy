variable "project_id" {
  description = "GCP project ID where Infra Manager will deploy"
  type        = string
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
  default     = "europe-west1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
