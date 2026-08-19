locals {
  sagemaker_regions = var.workbench_regions
}

# --- modules ---

module "sagemaker" {
  source = "./modules/sagemaker"

  for_each = toset(local.sagemaker_regions)
  region   = each.key
  prefix   = local.workbench_prefix
  tags     = local.tags
}


module "sagemaker_iam" {
  source         = "./modules/sagemaker-iam"
  prefix         = local.workbench_prefix
  principal_tags = local.principal_tags
  resource_tags  = local.resource_tags
  tags           = local.tags

  workspace_manager_role_name = local.workspace_manager_role_name
  workbench_user_role_name    = local.workbench_user_role_name
}
