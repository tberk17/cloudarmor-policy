# Project / location
variable "project_id" { type = string }
variable "region"     { type = string }
variable "zone"       { type = string }

# Existing unmanaged instance group (already created by you)
variable "instance_group_name" {
  description = "Existing unmanaged instance group name"
  type        = string
}

# LB settings
variable "service_port" {
  description = "Port your app listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path for health probing"
  type        = string
  default     = "/"
}

variable "lb_name_prefix" {
  description = "Prefix for LB resource names"
  type        = string
  default     = "app"
}

# Optional HTTPS
variable "domain" {
  description = "FQDN for managed SSL cert (leave empty for HTTP-only)"
  type        = string
  default     = ""
}
