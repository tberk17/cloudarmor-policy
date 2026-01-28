############################################
# Backend service: use your instance group #
############################################

# Regional HTTP health check
resource "google_compute_region_health_check" "hc" {
  name   = "web-hc"
  region = var.region
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Regional external HTTP(S) LB backend service (attach Cloud Armor)
resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-regional-bes"
  project               = var.project_id
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  session_affinity      = "NONE"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.hc.id]

  # Enable LB request logging so Cloud Armor per-request logs appear in Cloud Logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # >>> Your existing instance group (unmanaged); keep ONLY 'group' <<<
  backend {
    group = "https://www.googleapis.com/compute/v1/projects/cf-ciso-common-sandbo-nh/zones/europe-west1-b/instanceGroups/instance-group-1"
  }

  # Attach the REGIONAL Cloud Armor policy by self_link
  security_policy = google_compute_region_security_policy.waf.self_link
}

#########################################
# Frontend: URL map → proxy → FR (port 80)
#########################################

# Route all paths to the regional backend service
resource "google_compute_region_url_map" "urlmap" {
  name    = "web-urlmap"
  region  = var.region
  default_service = google_compute_region_backend_service.web_backend.id
}

# HTTP proxy that uses the regional URL map
resource "google_compute_region_target_http_proxy" "proxy" {
  name    = "web-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.urlmap.id
}

# Regional forwarding rule (public IP on port 80)
resource "google_compute_forwarding_rule" "http_fr" {
  name                 = "web-http-fr-regional"
  region               = var.region
  load_balancing_scheme = "EXTERNAL"
  target               = google_compute_region_target_http_proxy.proxy.id
  port_range           = "80"
}
