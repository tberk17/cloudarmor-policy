// spolicy.tf
// Cloud Armor security policy (module-managed)

module "security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "~> 7.0"  # current major from the official module registry

  project_id  = var.project_id
  name        = "my-test-security-policy"
  description = "Test Security Policy"
  type        = "CLOUD_ARMOR"

  # Baseline behavior; allow unless a rule matches
  default_rule_action = "allow"

  # Layer-7 DDoS visibility settings (optional)
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"

  # --- Start WAF rules in preview (log-only) ---
  # Recommended rollout: preview first, tune from logs, then enforce. 
  # (Set preview = false to enforce when you're ready.)
  pre_configured_rules = {
    sqli_v33 = {
      action            = "deny(403)"
      priority          = 1
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
      preview           = true
    }
  }

  # --- Example exemption / allowlist ---
  # Keep exemptions explicit with clear descriptions & distinct priorities.
  security_rules = {
    allow_corp_nat = {
      action        = "allow"
      priority      = 100
      src_ip_ranges = ["203.0.113.0/24"]
      description   = "Team exemption: corporate NAT"
      preview       = false
    }
  }

  # You can also add:
  # custom_rules = { ... }                 # CEL expressions
  # threat_intelligence_rules = { ... }    # requires enterprise features
}
