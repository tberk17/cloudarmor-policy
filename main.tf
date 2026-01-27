provider "google" {
  project = "cf-ciso-common-sandbo-nh"
}

# Use the older module release compatible with TF 1.5.x
module "cloudarmor_policy" {
  source  = "metro-digital/cf-cloudarmor-policy/google"
  version = "0.1.1"

  project_id = "cf-ciso-common-sandbo-nh"
}

output "cloudarmor_policy_name" {
  value = module.cloudarmor_policy.security_policy
}
