############################################
# Backend service: use your instance group #
############################################

# Health check for the backend (HTTP)
resource "google_compute_http_health_check" "hc" {
  name         = "web-hc"
  request_path = "/"
}

# Global external HTTP(S) LB backend service (attach Cloud Armor)
resource "google_compute_backend_service" "web_backend" {
  name                    = "web-global-bes"
  project                 = var.project_id
  protocol                = "HTTP"
  port_name               = "http"
  timeout_sec             = 30
  session_affinity        = "NONE"
  connection_draining_timeout_sec = 0

  # Global external HTTP(S) load balancer
  load_balancing_scheme   = "EXTERNAL"

  health_checks = [google_compute_http_health_check.hc.id]

  # Enable LB request logging so Cloud Armor per-request logs appear
  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # >>> Your instance group self link (europe-west1-b) <<<
  backend {
    group           = "https://www.googleapis.com/compute/v1/projects/cf-ciso-common-sandbo-nh/zones/europe-west1-b/instanceGroups/instance-group-1"
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  # ATTACH Cloud Armor policy from the module (use self_link, not name)
  security_policy = module.security_policy.policy.self_link
}

#########################################
# Frontend: URL map → proxy → FR (port 80)
#########################################

# Route all paths to the backend service
resource "google_compute_url_map" "urlmap" {
  name            = "web-urlmap"
  default_service = google_compute_backend_service.web_backend.id
}

# HTTP proxy that uses the URL map
resource "google_compute_target_http_proxy" "proxy" {
  name   = "web-http-proxy"
  url_map = google_compute_url_map.urlmap.id
}

# Global forwarding rule (public IP on port 80)
resource "google_compute_global_forwarding_rule" "http_fr" {
  name       = "web-http-fr"
  target     = google_compute_target_http_proxy.proxy.id
  port_range = "80"
}
