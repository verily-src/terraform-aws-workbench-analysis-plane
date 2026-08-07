locals {

  # --- workflow manager gcp service account
  # construct the JWT attributes for the WFM GCP service account, to be used in the IAM policies
  workflow_manager_gcp_service_account = {
    aud = var.gcp_oauth_accounts[var.environment].oauth.audience
    sub = var.gcp_oauth_accounts[var.environment].oauth.ids.workflow_manager
  }

  # --- role names and unique ids
  # gather the required iam role names for the kms_iam module
  # note that this is an output value from the module!
  workflow_manager_role_name = module.workflow_manager_iam.workflow_manager_role_name
  workflow_manager_role_arn  = module.workflow_manager_iam.workflow_manager_role_arn
}

# --- modules ---

module "workflow_manager_iam" {
  source = "./modules/workflow-manager-iam"
  prefix = local.workbench_prefix
  tags   = local.workflow_tags

  workflow_manager_gcp_service_account = local.workflow_manager_gcp_service_account
  regression_testing_assume_role_arns  = var.regression_testing_assume_role_arns
}
