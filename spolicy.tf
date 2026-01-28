module "security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "~> 7.0"

  project_id                           = var.project_id
  name                                 = "my-test-security-policy"
  description                          = "Test Security Policy"
  default_rule_action                  = "allow"
  type                                 = "CLOUD_ARMOR"
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"

  # Start WAF rules in preview
  pre_configured_rules = {
    sqli_v33 = {
      action            = "deny(403)"
      priority          = 1
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

  # (optional) custom_rules / threat_intelligence_rules…
}

resource "google_compute_http_health_check" "hc" {
  name         = "dummy-hc"
  request_path = "/"
}

resource "google_compute_backend_service" "default" {
  name                    = "dummy-backend-service"
  project                 = var.project_id
  protocol                = "HTTP"
  port_name               = "http"
  timeout_sec             = 30
  session_affinity        = "NONE"
  connection_draining_timeout_sec = 0
  load_balancing_scheme   = "EXTERNAL"

  health_checks = [google_compute_http_health_check.hc.id]

  # Enable LB request logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # ATTACH Cloud Armor (use self_link, not name)
  security_policy = module.security_policy.policy.self_link
}
