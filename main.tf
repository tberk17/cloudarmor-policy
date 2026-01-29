resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  policy_name = "test-casp-policy-${random_id.suffix.hex}"
}

module "cloud_armor" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "~> 7.0"

  project_id                           = var.projectId
  name                                 = local.policy_name
  description                          = "Test Cloud Armor security policy with preconfigured rules, security rules and custom rules"
  default_rule_action                  = "deny(502)"
  type                                 = "CLOUD_ARMOR"
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"
  user_ip_request_headers              = ["True-Client-IP"]

  # --- your WAF/security/custom/adaptive/threat rules exactly as before ---
  # (keep the same rule blocks you already have here)
  # I’ve left them out for brevity; no name changes are needed inside those maps.
}
