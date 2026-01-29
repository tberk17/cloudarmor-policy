terraform {
  required_version = ">= 1.5.0, < 1.11.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.32, < 8.0"
    }
  }
}
