module "security_policy" {
  # Regional submodule (required for regional external ALB)
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/regional-backend-security-policy"
  version = "7.0.0"

  project_id          = var.project_id
  name                = "my-test-security-policy-ew1"   # you can keep name, but see note below
  description         = "Test Security Policy"
  default_rule_action = "allow"
  type                = "CLOUD_ARMOR"

  # REQUIRED for regional policy:
  region = "europe-west1"

  # NOTE: layer_7_ddos_defense_* removed (global-only Adaptive Protection settings)
  # Your rules below are unchanged.

  threat_intelligence_rules = {
    malicious_ips = {
      action      = "deny(403)"
      priority    = 1100
      feed        = "iplist-known-malicious-ips"
      description = "Deny traffic from known malicious IPs"
    }

    crypto_miners = {
      action      = "deny(403)"
      priority    = 1200
      feed        = "iplist-crypto-miners"
      description = "Deny traffic from known crypto miners IP list"
    }

    vpn_providers = {
      action      = "deny(403)"
      priority    = 1300
      feed        = "iplist-vpn-providers"
      preview     = true
      description = "Low-reputation VPN providers (preview first)"
    }

    anon_proxies = {
      action      = "deny(403)"
      priority    = 1400
      feed        = "iplist-anon-proxies"
      description = "Deny traffic from known open anonymous proxies"
    }

    tor_exit_nodes = {
      action      = "deny(403)"
      priority    = 1500
      feed        = "iplist-tor-exit-nodes"
      description = "Tor exit nodes"
    }

    allow_crawlers = {
      action      = "allow"
      priority    = 1600
      feed        = "iplist-search-engines-crawlers"
      description = "Allow search engine crawlers"
    }
  }

  pre_configured_rules = {
    waf_sqli = {
      action            = "deny(403)"
      priority          = 3000
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: SQL Injection Protection (v33-stable)"
    }

    waf_xss = {
      action            = "deny(403)"
      priority          = 3010
      target_rule_set   = "xss-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Cross-Site Scripting Protection (v33-stable)"
    }

    waf_lfi = {
      action            = "deny(403)"
      priority          = 3020
      target_rule_set   = "lfi-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Local File Inclusion Protection (v33-stable)"
    }

    waf_rce = {
      action            = "deny(403)"
      priority          = 3030
      target_rule_set   = "rce-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Remote Code Execution Protection (v33-stable)"
    }

    waf_rfi = {
      action            = "deny(403)"
      priority          = 3040
      target_rule_set   = "rfi-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Remote File Inclusion Protection (v33-stable)"
    }

    waf_method_enforcement = {
      action            = "deny(403)"
      priority          = 3050
      target_rule_set   = "methodenforcement-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: HTTP Method Enforcement (v33-stable)"
    }

    waf_scanner_detection = {
      action            = "deny(403)"
      priority          = 3060
      target_rule_set   = "scannerdetection-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Scanner Detection (v33-stable)"
    }

    waf_protocol_attack = {
      action            = "deny(403)"
      priority          = 3070
      target_rule_set   = "protocolattack-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Protocol Attack Protection (v33-stable)"
    }

    waf_php = {
      action            = "deny(403)"
      priority          = 3080
      target_rule_set   = "php-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: PHP Injection Attack Protection (v33-stable)"
    }

    waf_session_fixation = {
      action            = "deny(403)"
      priority          = 3090
      target_rule_set   = "sessionfixation-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Session Fixation Protection (v33-stable)"
    }

    waf_java = {
      action            = "deny(403)"
      priority          = 3100
      target_rule_set   = "java-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Java Attack Protection (v33-stable)"
    }

    waf_nodejs = {
      action            = "deny(403)"
      priority          = 3110
      target_rule_set   = "nodejs-v33-stable"
      sensitivity_level = 1
      description       = "OWASP CRS: Node.js Attack Protection (v33-stable)"
    }
  }

  security_rules = {}
  custom_rules   = {}
}
