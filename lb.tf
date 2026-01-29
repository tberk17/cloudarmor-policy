# lb.tf

# 1) Unmanaged instance group containing the existing VM
resource "google_compute_instance_group" "unmanaged" {
  name = "${var.lb_name_prefix}-igm"
  zone = var.zone

  # Reference existing VM by self_link
  instances = [
    "https://www.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${var.vm_name}"
  ]

  named_port {
    name = "http"
    port = var.service_port
  }
}

# 2) Health check (HTTP)
resource "google_compute_health_check" "http" {
  name = "${var.lb_name_prefix}-hc"

  http_health_check {
    port_specification = "USE_NAMED_PORT"
    request_path       = var.health_check_path
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# 3) Backend service with Cloud Armor attached
resource "google_compute_backend_service" "app_backend" {
  name        = "${var.lb_name_prefix}-bes"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  health_checks = [google_compute_health_check.http.id]

  backend {
    group = google_compute_instance_group.unmanaged.self_link
  }

  # <-- Attach the Cloud Armor policy created by your module
  security_policy = data.google_compute_security_policy.baseline.self_link
}

# 4) URL map
resource "google_compute_url_map" "default" {
  name            = "${var.lb_name_prefix}-urlmap"
  default_service = google_compute_backend_service.app_backend.self_link
}

# 5) HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.lb_name_prefix}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# Optional: reserve a static global IP so you can point DNS at it
resource "google_compute_global_address" "lb_ip" {
  name = "${var.lb_name_prefix}-ip"
}

# 6) Global forwarding rule (HTTP, port 80)
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.lb_name_prefix}-http-fr"
  target                = google_compute_target_http_proxy.default.self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.lb_ip.address
}
