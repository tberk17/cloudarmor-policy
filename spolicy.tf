# spolicy.tf (regional Cloud Armor policy + rules)

# Regional Cloud Armor policy (CLOUD_ARMOR backend policy)
resource "google_compute_region_security_policy" "waf" {
  name        = "baseline-web-waf-regional"
  description = "Baseline WAF policy (regional)"
  region      = var.region            # e.g., "europe-west1"
  type        = "CLOUD_ARMOR"
}

# Example: OWASP/SQLi rule in preview (log-only)
resource "google_compute_region_security_policy_rule" "sqli_preview" {
  region          = var.region
  security_policy = google_compute_region_security_policy.waf.name
  priority        = 10
  action          = "deny(403)"
  preview         = true

  # Use preconfigured WAF expression IDs (example shown)
  match {
    preconfigured_waf_config {
      # replace/add IDs from the OWASP CRS v3.3 SQLi set as needed
      expression_ids = ["owasp-crs-v033-Id942100-sqli"]
    }
  }
}

# Example exemption / allowlist (corp NAT), high priority
resource "google_compute_region_security_policy_rule" "allow_corp_nat" {
  region          = var.region
  security_policy = google_compute_region_security_policy.waf.name
  priority        = 100
  action          = "allow"
  preview         = false

  match {
    versioned_expr = "SRC_IPS_V1"
    config { src_ip_ranges = ["203.0.113.0/24"] }
  }
}
