locals {
  # --- role names and unique ids
  # gather the required iam role names neededfor the kms_iam module
  # note that this is an output value from the module!
  external_access_role_arn = module.external_access_iam.external_access_role_arn
}

# -- - modules ---

module "external_access_iam" {
  source = "./modules/external-access-iam"

  prefix         = local.workbench_prefix
  sid_prefix     = local.sid_prefix
  account_id     = local.account_id
  principal_tags = local.principal_tags
  tags           = local.tags

  workspace_manager_role_arn = local.workspace_manager_role_arn
}

