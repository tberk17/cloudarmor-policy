data "google_compute_security_policy" "baseline" {
  name    = var.name        # must match the policy name passed to your module (default: "metro-baseline")
  project = var.project_id
}
