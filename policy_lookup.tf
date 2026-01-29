data "google_compute_security_policy" "policy" {
  name    = local.policy_name
  project = var.projectId
}
