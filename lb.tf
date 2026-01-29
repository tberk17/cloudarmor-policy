# Use your existing unmanaged instance group
data "google_compute_instance_group" "igm" {
  name = var.instanceGroup
  zone = var.gcpZone
}

# Health check (HTTP) – explicit port & path
resource "google_compute_health_check" "http" {
  name = "${var.lbNamePrefix}-hc"

  http_health_check {
    port         = var.servicePort
    request_path = var.healthCheckPath
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# Backend service with Cloud Armor attached
resource "google_compute_backend_service" "app_backend" {
  name        = "${var.lbNamePrefix}-bes"
  protocol    = "HTTP"
  port_name   = "http"       # ensure IG has named port: http:<servicePort>
  timeout_sec = 30

  health_checks = [google_compute_health_check.http.id]

  backend {
    group = data.google_compute_instance_group.igm.self_link
  }

  # Attach Cloud Armor policy (enforcement point)
  security_policy = data.google_compute_security_policy.policy.self_link
}

# URL map
resource "google_compute_url_map" "default" {
  name            = "${var.lbNamePrefix}-urlmap"
  default_service = google_compute_backend_service.app_backend.self_link
}

# HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.lbNamePrefix}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# Global IP
resource "google_compute_global_address" "lb_ip" {
  name = "${var.lbNamePrefix}-ip"
}

# HTTP forwarding rule (80)
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.lbNamePrefix}-http-fr"
  target                = google_compute_target_http_proxy.default.self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.lb_ip.address
}

# === Optional HTTPS (if var.domain set) ===
resource "google_compute_managed_ssl_certificate" "cert" {
  count = var.domain != "" ? 1 : 0
  name  = "${var.lbNamePrefix}-cert"
  managed { domains = [var.domain] }
}

resource "google_compute_target_https_proxy" "https" {
  count            = var.domain != "" ? 1 : 0
  name             = "${var.lbNamePrefix}-https-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.cert[0].self_link]
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = var.domain != "" ? 1 : 0
  name                  = "${var.lbNamePrefix}-https-fr"
  target                = google_compute_target_https_proxy.https[0].self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.lb_ip.address
}
