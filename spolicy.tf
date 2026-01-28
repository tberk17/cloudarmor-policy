# Regional Cloud Armor policy (backend policy for regional ALB)
resource "google_compute_region_security_policy" "waf" {
  name        = "baseline-web-waf-regional"
  description = "Baseline WAF policy (regional)"
  region      = var.region
  type        = "CLOUD_ARMOR"
}

# OWASP SQLi (CRS 3.3) in PREVIEW (log-only) via CEL
resource "google_compute_region_security_policy_rule" "sqli_preview" {
  region          = var.region
  security_policy = google_compute_region_security_policy.waf.name
  priority        = 10
  action          = "deny(403)"
  preview         = true

  match {
    # Evaluate the preconfigured WAF rule set with sensitivity tuning
    expr {
      expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 4})"
    }
  }
}

# Example exemption / allowlist rule (team-specific)
resource "google_compute_region_security_policy_rule" "allow_corp_nat" {
  region          = var.region
  security_policy = google_compute_region_security_policy.waf.name
  priority        = 100
  action          = "allow"
  preview         = false

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["203.0.113.0/24"] # change/remove to fit your exemptions
    }
  }
}
