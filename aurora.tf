# --- locals ---

# The configuration for Aurora clusters consists of common global settings, specified in the locals
# section below. The aurora submodule is passed the regional clusters configuration, which contains
# optional parameters per cluster, allowing overriding the common global settings.

locals {
  # --- aurora features
  # this extracts the aurora serverless feature configuration from the features variable. 
  aurora = try(var.features.aurora_serverless, {
    enabled = false
  })

  # --- aurora clusters
  # this extracts the aurora clusters configuration from the features variable.
  aurora_clusters = try(local.aurora.clusters, {})

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

  # --- deletion protection
  # global flag for all regions - can be overwritten in the features variable.
  # for unit/regression testing, this value is set to false to allow cleanup.
  aurora_deletion_protection = (length(var.regression_testing_assume_role_arns) > 0 || var.enable_resource_protection == false) ? false : true
}

# --- modules ---

module "aurora_cluster" {
  for_each = {
    for region, clusters in local.aurora_clusters : region => clusters
    if contains(var.workbench_regions, region) && local.aurora.enabled
  }
  source                     = "./modules/aurora"
  region                     = each.key
  clusters                   = each.value
  workbench_regions          = var.workbench_regions
  prefix                     = local.workbench_prefix
  postgresql_version         = local.aurora_postgresql_version
  master_username            = local.aurora_master_username
  aws_managed_password       = local.aurora_aws_managed_password
  iam_authentication_enabled = local.aurora_iam_authentication_enabled
  deletion_protection        = local.aurora_deletion_protection

  # vpc
  vpc_id                   = module.vpc[each.key].vpc_id
  vpc_private_subnet_cidrs = module.vpc[each.key].private_subnet_cidrs

  # tags
  tags = merge(
    local.tags,
    try(each.value.additional_tags, {})
  )

  resource_tags = local.resource_tags
}

module "aurora_iam" {
  for_each = local.aurora.enabled ? toset(["this"]) : toset([])

  source                 = "./modules/aurora-iam"
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
