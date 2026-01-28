module "security_policy_regional" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/regional-backend-security-policy"
  version = "~> 7.0"

  project_id          = var.project_id
  region              = var.region                 # e.g., "europe-west1"
  name                = "baseline-web-waf-regional"
  description         = "Baseline WAF policy (regional)"
  type                = "CLOUD_ARMOR"
  default_rule_action = "allow"

  # Start preconfigured OWASP rules in preview (log-only)
  pre_configured_rules = {
    sqli_v33 = {
      action            = "deny(403)"
      priority          = 10
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
      preview           = true
    }
  }

  # Example exemption / allowlist
  security_rules = {
    allow_corp_nat = {
      action        = "allow"
      priority      = 100
      src_ip_ranges = ["203.0.113.0/24"]
      description   = "Team exemption: corporate NAT"
      preview       = false
    }
  }
}
