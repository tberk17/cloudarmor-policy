module "security_policy" { ①
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = ">= 0.1.0"
 
  project_id                           = local.project_id #your project id
  name                                 = "my-test-security-policy"
  description                          = "Test Security Policy"
  default_rule_action                  = "allow"
  type                                 = "CLOUD_ARMOR"
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"
  
  [...]

  pre_configured_rules = { ②
    	"sqli_sensitivity_level_4" = {
      	action          = "deny(502)"
      	priority        = 1
      	target_rule_set = "sqli-v33-stable"
    	}
	}
  security_rules = {
	    [...]
	}
  custom_rules = {
	    [...]
	} 
  threat_intelligence_rules = {
	    [...]
	}  
resource "google_compute_backend_service" "default" { ③
  name                            = "dummy-backend-service"
  connection_draining_timeout_sec = 0
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  security_policy                 = "my-test-security-policy" 
  project                         = local.project_id
}
