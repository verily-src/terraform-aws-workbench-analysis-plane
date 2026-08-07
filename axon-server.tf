locals {

  # --- axon server gcp service account
  # construct the JWT attributes for the Axon Server GCP service account, to be used in the IAM policies
  axon_server_gcp_service_account = {
    aud = var.gcp_oauth_accounts[var.environment].oauth.audience
    sub = var.gcp_oauth_accounts[var.environment].oauth.ids.axon_server
  }

  # --- role names
  # gather the required iam role names
  axon_server_role_name = module.axon_server_iam.axon_server_role_name
  axon_server_role_arn  = module.axon_server_iam.axon_server_role_arn
}

# --- modules ---

module "axon_server_iam" {
  source = "./modules/axon-server-iam"
  prefix = local.workbench_prefix
  tags   = local.tags

  axon_server_gcp_service_account = local.axon_server_gcp_service_account
}
