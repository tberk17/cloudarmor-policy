###############################################
# variables.tf
# Inputs required by the LB + Cloud Armor setup
###############################################

# === Project / location ===
variable "project_id" {
  description = "GCP project ID where resources are created"
  type        = string
}

variable "region" {
  description = "Region for regional resources and provider default (e.g., europe-west1)"
  type        = string
}

# Use gcp_zone (we avoid 'zone' since your deployment UI rejected it)
variable "gcp_zone" {
  description = "Zone where your existing VM / instance group lives (e.g., europe-west1-b)"
  type        = string
}

# === Existing backend (you already have this IG) ===
variable "instance_group" {
  description = "Name of the existing unmanaged instance group"
  type        = string
}

# === Load balancer settings ===
variable "service_port" {
  description = "Port your app listens on (must match the IG named port 'http:<service_port>')"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used by the health checker (should return 200 OK)"
  type        = string
  default     = "/"
}

variable "lb_name_prefix" {
  description = "Prefix for LB resource names"
  type        = string
  default     = "app"
}

# === Optional HTTPS (managed SSL cert) ===
# Leave empty for HTTP-only. If you set a domain, point its A-record to the lb_global_ip output.
variable "domain" {
  description = "FQDN for a managed SSL certificate (optional)"
  type        = string
  default     = ""
}
