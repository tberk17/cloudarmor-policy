variable "project_id" {
  description = "GCP project ID where Infra Manager will deploy"
  type        = string
}

variable "region" {
  description = "Default region for provider (not a resource location)"
  type        = string
  default     = "europe-west1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
