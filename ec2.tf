# --- modules ---

module "ec2_iam" {
  source         = "./modules/ec2-iam"
  prefix         = local.workbench_prefix
  sid_prefix     = local.sid_prefix
  resource_tags  = local.resource_tags
  principal_tags = local.principal_tags
  tags           = local.tags

  workspace_manager_role_name = local.workspace_manager_role_name
  workbench_user_role_name    = local.workbench_user_role_name
  axon_server_role_name       = local.axon_server_role_name
  app_instance_role_name      = local.app_instance_role_name
  app_instance_role_arn       = local.app_instance_role_arn
  app_instance_role_unique_id = local.app_instance_unique_id
}
