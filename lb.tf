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

# Regional external (managed) HTTP(S) LB backend service
resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-regional-bes"
  project               = var.project_id
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http"        # your instance group must have named port "http" -> 80
  timeout_sec           = 30
  session_affinity      = "NONE"

  # ✅ Managed regional external ALB (supports backend logging)
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [google_compute_region_health_check.hc.id]

  # ✅ Enable LB request logging (shows Cloud Armor preview/enforced outcomes)
  log_config {
    enable      = true
    sample_rate = 1.0
  }

