locals {
  object_key = "config.json"

  workbench_global_schema   = jsondecode(module.discovery_schemas.global)
  workbench_regional_schema = jsondecode(module.discovery_schemas.regional)
}

# --- modules ---

module "discovery_schemas" {
  source = "./modules/discovery-schemas"
}

module "discovery_bucket" {
  source     = "./modules/discovery"
  prefix     = local.workbench_prefix
  sid_prefix = local.sid_prefix
  account_id = local.account_id
  versioning = "Enabled"
  tags       = local.tags

  gcp_service_accounts                = local.gcp_service_accounts
  app_instance_role_arns              = [local.app_instance_role_arn]
  force_destroy                       = length(var.regression_testing_assume_role_arns) > 0 ? true : false
  regression_testing_assume_role_arns = var.regression_testing_assume_role_arns
}
