locals {
  # --- app_instance role names
  # this gathers the role names for the app_instance iam roles.
  # note this is an output of the app_instance-iam module
  app_instance_role_arn     = module.app_instance_iam.app_instance_role_arn
  app_instance_role_name    = module.app_instance_iam.app_instance_role_name
  app_instance_unique_id    = module.app_instance_iam.app_instance_unique_id
  app_instance_profile_name = module.app_instance_iam.app_instance_instance_profile_name
}

# --- modules ---

module "app_instance_iam" {
  source         = "./modules/app-instance-iam"
  prefix         = local.workbench_prefix
  sid_prefix     = local.sid_prefix
  principal_tags = local.principal_tags
  resource_tags  = local.resource_tags
  tags           = local.tags

  workbench_user_role_name = local.workbench_user_role_name
}
