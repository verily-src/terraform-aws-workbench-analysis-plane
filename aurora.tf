# --- locals ---

locals {
  # --- aurora features
  # this extracts the aurora serverless feature configuration from the features variable. 
  aurora = try(var.features.aurora_serverless, {
    enabled          = false
    excluded_regions = []
  })

  # --- aurora regions
  # if the aurora feature is not enabled, set aurora_regions to an empty list, otherwise
  # it will adopt the global workbench regions.
  # this allows specific regions to be excluded from aurora clusters
  # in the event that aurora serverless v2 is not available in all workbench regions yet. 
  aurora_base    = local.aurora.enabled ? var.workbench_regions : []
  aurora_regions = setsubtract(local.aurora_base, local.aurora.excluded_regions)

  # --- aurora master username
  # this sets the master username for the aurora clusters.
  aurora_master_username = try(local.aurora.master_username, "wbadmin")

  # --- postgresql version
  # this sets the major version number for the aurora postgres clusters
  aurora_postgresql_version = try(local.aurora.postgresql_version, "16.11")

  # --- aws managed password 
  # this is always true for aurora serverless v2
  aurora_aws_managed_password = true

  # --- iam authentication enabled
  # this is always true for aurora serverless v2
  aurora_iam_authentication_enabled = true

  # --- restore to point in time configuration
  # this sets the point-in-time recovery configuration for the aurora clusters.
  aurora_restore_to_point_in_time = try(local.aurora.restore_to_point_in_time, null)
}

# --- modules ---

module "aurora_cluster" {
  source = "./modules/aurora"

  for_each                   = toset(local.aurora_regions)
  region                     = each.value
  prefix                     = local.workbench_prefix
  postgresql_version         = local.aurora_postgresql_version
  master_username            = local.aurora_master_username
  aws_managed_password       = local.aurora_aws_managed_password
  iam_authentication_enabled = local.aurora_iam_authentication_enabled
  restore_to_point_in_time   = local.aurora_restore_to_point_in_time

  # vpc
  vpc_id                   = module.vpc[each.value].vpc_id
  vpc_private_subnet_cidrs = module.vpc[each.value].private_subnet_cidrs

  # tags
  resource_tags = local.resource_tags
  tags          = local.tags

  # delete protection
  deletion_protection = (length(var.regression_testing_assume_role_arns) > 0 || var.enable_resource_protection == false) ? false : true
}

module "aurora_iam" {
  source = "./modules/aurora-iam"

  for_each               = local.aurora.enabled ? toset(["this"]) : toset([])
  account_id             = local.account_id
  prefix                 = local.workbench_prefix
  aurora_master_username = local.aurora_master_username
  sid_prefix             = local.sid_prefix
  principal_tags         = local.principal_tags
  resource_tags          = local.resource_tags
  tags                   = local.tags

  workspace_manager_role_name = local.workspace_manager_role_name

  aurora_user_role_names = compact([
    local.workbench_user_role_name
  ])
}
