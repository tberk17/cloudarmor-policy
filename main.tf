###############################################################################
# Providers & API
###############################################################################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.30.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

###############################################################################
# Existing unmanaged instance group
###############################################################################
data "google_compute_instance_group" "app" {
  name = var.instance_group_name
  zone = var.instance_group_zone
}

# Add required named port to the unmanaged IG
resource "google_compute_instance_group_named_port" "ig_named_port" {
  group = data.google_compute_instance_group.app.name
  zone  = var.instance_group_zone
  name  = var.backend_named_port_name
  port  = var.backend_named_port
}

###############################################################################
# Regional Cloud Armor policy (REGIONAL submodule)
# NOTE: Provide recaptcha_redirect_site_key if you keep redirect rules.
###############################################################################
resource "random_id" "suffix" {
  byte_length = 4
}

module "regional_cloud_armor" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/regional-backend-security-policy"
  version = "~> 7.0" # uses the module with regional policy support [1](https://github.com/GoogleCloudPlatform/terraform-google-cloud-armor)

  project_id = var.project_id
  region     = var.region

  name        = "regional-casp-policy-${random_id.suffix.hex}"
  description = "Regional Cloud Armor policy (migrated from your global example)"
  type        = "CLOUD_ARMOR"

  # If you want to use GOOGLE_RECAPTCHA redirects in rules below, set:
  # recaptcha_redirect_site_key = "<projects/.../keys/...>"

  # --- Preconfigured WAF Rules (kept) ---
  pre_configured_rules = {
    xss-stable_level_2_with_exclude = {
      action            = "deny(502)"
      priority          = 2
      preview           = true
      target_rule_set   = "xss-v33-stable"
      sensitivity_level = 2
      exclude_target_rule_ids = [
        "owasp-crs-v030301-id941380-xss",
        "owasp-crs-v030301-id941280-xss",
      ]
    }
    php-stable_level_0_with_include = {
      action                  = "deny(502)"
      priority                = 3
      description             = "PHP Sensitivity Level 0 with included rules"
      target_rule_set         = "php-v33-stable"
      include_target_rule_ids = [
        "owasp-crs-v030301-id933190-php",
        "owasp-crs-v030301-id933111-php",
      ]
    }
  }

  # --- Security Rules (kept) ---
  security_rules = {
    allow_whitelisted_ip_ranges = {
      action        = "allow"
      priority      = 11
      description   = "Allow whitelisted IP address ranges"
      src_ip_ranges = ["190.210.69.12"]
      preview       = false
    }

    redirect_project_drop = {
      action        = "redirect"
      priority      = 12
      description   = "Redirect IP address from project drop"
      src_ip_ranges = ["190.217.68.212", "45.116.227.69"]
      redirect_type = "GOOGLE_RECAPTCHA"
      # Requires: recaptcha_redirect_site_key at module level
    }

    rate_ban_project_dropthirty = {
      action        = "rate_based_ban"
      priority      = 13
      description   = "Rate based ban for address from project dropthirty only if they cross ban threshold"
      src_ip_ranges = ["190.217.68.213", "45.116.227.70"]
      rate_limit_options = {
        ban_duration_sec                     = 300
        enforce_on_key                       = "ALL"
        exceed_action                        = "deny(502)"
        rate_limit_http_request_count        = 10
        rate_limit_http_request_interval_sec = 60
        ban_http_request_count               = 1000
        ban_http_request_interval_sec        = 300
      }
    }

    throttle_project_droptwenty = {
      action        = "throttle"
      priority      = 14
      description   = "Throttle IP addresses from project droptwenty"
      src_ip_ranges = ["190.217.68.214", "45.116.227.71"]
      rate_limit_options = {
        exceed_action                        = "deny(502)"
        rate_limit_http_request_count        = 10
        rate_limit_http_request_interval_sec = 60
      }
    }
  }

  # --- Custom Rules (kept) ---
  custom_rules = {
    allow_specific_regions = {
      action      = "allow"
      priority    = 21
      description = "Allow specific Regions"
      expression  = <<-EOT
        '[US,AU,BE]'.contains(origin.region_code)
      EOT
    }
    throttle_specific_ip = {
      action      = "throttle"
      priority    = 23
      description = "Throttle specific IP address in US Region"
      expression  = <<-EOT
        origin.region_code == "US" && inIpRange(origin.ip, '47.185.201.159/32')
      EOT
      rate_limit_options = {
        exceed_action                        = "deny(502)"
        rate_limit_http_request_count        = 10
        rate_limit_http_request_interval_sec = 60
      }
    }
    rate_ban_specific_ip = {
      action     = "rate_based_ban"
      priority   = 24
      expression = <<-EOT
        inIpRange(origin.ip, '47.185.201.160/32')
      EOT
      rate_limit_options = {
        ban_duration_sec                     = 120
        enforce_on_key                       = "ALL"
        exceed_action                        = "deny(502)"
        rate_limit_http_request_count        = 10
        rate_limit_http_request_interval_sec = 60
        ban_http_request_count               = 10000
        ban_http_request_interval_sec        = 600
      }
    }
    test-sl = {
      action      = "deny(502)"
      priority    = 100
      description = "test Sensitivity level policies"
      preview     = true
      expression  = <<-EOT
        evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 4, 'opt_out_rule_ids': ['owasp-crs-v030301-id942350-sqli', 'owasp-crs-v030301-id942360-sqli']})
      EOT
    }
  }

  # NOTE: Adaptive Protection auto-deploy removed here (global-only feature). [1](https://github.com/GoogleCloudPlatform/terraform-google-cloud-armor)
  # NOTE: If you use Threat Intelligence rules and have Enterprise, we can try to port them;
  #       support varies—happy to add once you confirm subscription.
}

###############################################################################
# Regional Health Check (Envoy / Regional External HTTP LB)
###############################################################################
resource "google_compute_region_health_check" "hc" {
  name   = "app-hc"
  region = var.region

  http_health_check {
    port_specification = "USE_FIXED_PORT"
    port               = 80
    request_path       = "/"
  }

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

###############################################################################
# Regional Backend Service (attach REGIONAL Cloud Armor policy here)
###############################################################################
resource "google_compute_region_backend_service" "backend" {
  provider              = google-beta
  name                  = "app-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  port_name             = var.backend_named_port_name

  health_checks = [google_compute_region_health_check.hc.id]

  backend {
    group           = data.google_compute_instance_group.app.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  # Attach the REGIONAL Cloud Armor policy
  security_policy = module.regional_cloud_armor.policy.self_link  # [1](https://github.com/GoogleCloudPlatform/terraform-google-cloud-armor)
}

###############################################################################
# Regional URL Map / Target Proxy / Forwarding Rule (HTTP)
###############################################################################
resource "google_compute_region_url_map" "url_map" {
  name   = "app-url-map"
  region = var.region

  default_service = google_compute_region_backend_service.backend.id
}

resource "google_compute_region_target_http_proxy" "http_proxy" {
  name   = "app-http-proxy"
  region = var.region
  url_map = google_compute_region_url_map.url_map.id
}

# Regional static IP for the LB
resource "google_compute_address" "lb_ip" {
  name   = "app-lb-ip"
  region = var.region
}

resource "google_compute_forwarding_rule" "http" {
  name                  = "app-http-fr"
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.http_proxy.id
  ip_address            = google_compute_address.lb_ip.self_link
  allow_global_access   = true
}

###############################################################################
# Outputs
###############################################################################
output "regional_lb_ip" {
  value = google_compute_address.lb_ip.address
}

output "regional_http_endpoint" {
  value = "http://${google_compute_address.lb_ip.address}"
}
