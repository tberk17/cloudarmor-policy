output "lb_global_ip" {
  description = "Global IP of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "http_url" {
  description = "HTTP URL via the LB"
  value       = "http://${google_compute_global_address.lb_ip.address}"
}

output "https_url" {
  description = "HTTPS URL (if domain set)"
  value       = var.domain != "" ? "https://${var.domain}" : null
}

