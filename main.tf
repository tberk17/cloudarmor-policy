terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.14, < 8"
    }
  }
}

provider "google" {
  project = "cf-ciso-common-sandbo-nh"
}

# Create a Metro-compliant Cloud Armor policy in your project
module "cloudarmor_policy" {
  source  = "metro-digital/cf-cloudarmor-policy/google"
  version = "~> 0.2"

  project_id = "cf-ciso-common-sandbo-nh"

  # Start Adaptive Protection in preview so it only observes at first
  adaptive_protection_auto_deploy_overwrites = { preview = true }
}

# You'll use this output name when attaching to the LB backend
output "cloudarmor_policy_name" {
  value = module.cloudarmor_policy.security_policy
}
