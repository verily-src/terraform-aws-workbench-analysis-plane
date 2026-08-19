locals {

  # --- workspace manager gcp service account
  # construct the JWT attributes for the WSM GCP service account from the input variable, to be used in the IAM policies
  workspace_manager_gcp_service_account = {
    aud = var.gcp_oauth_accounts[var.environment].oauth.audience
    sub = var.gcp_oauth_accounts[var.environment].oauth.ids.workspace_manager
  }

  # --- role names and unique ids
  # gather the required iam role names for the kms_iam module
  # note that this is an output value from the module!
  workspace_manager_role_name = module.workspace_manager_iam.workspace_manager_role_name
  workspace_manager_role_arn  = module.workspace_manager_iam.workspace_manager_role_arn
  workspace_manager_unique_id = module.workspace_manager_iam.workspace_manager_role_unique_id

  workbench_user_role_name = module.workspace_manager_iam.workbench_user_role_name
  workbench_user_role_arn  = module.workspace_manager_iam.workbench_user_role_arn
  workbench_user_unique_id = module.workspace_manager_iam.workbench_user_role_unique_id
}

# --- modules ---

module "workspace_manager_iam" {
  source = "./modules/workspace-manager-iam"
  prefix = local.workbench_prefix
  tags   = local.tags

  workspace_manager_gcp_service_account = local.workspace_manager_gcp_service_account
  regression_testing_assume_role_arns   = var.regression_testing_assume_role_arns
}
