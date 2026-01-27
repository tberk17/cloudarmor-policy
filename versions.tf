terraform {
  required_version = ">= 1.3"   # works with your 1.5.7 runtime
  required_providers {
    google = {
      source  = "hashicorp/google"
      # 0.1.1 of the module works with provider 5.x/6.x; keep it flexible:
      version = ">= 5.1, < 7.0"
    }
  }
}
``
