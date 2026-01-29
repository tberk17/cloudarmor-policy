# Get the policy that the module just created (by name)
data "google_compute_security_policy" "policy" {
  name    = local.policy_name
  project = var.project_id
}
