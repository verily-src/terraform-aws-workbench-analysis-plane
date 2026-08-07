locals {
  # --- efs feature configuration
  efs = try(var.features.efs, {
    enabled          = false
    filesystems      = {}
    excluded_regions = []
  })

  efs_enabled          = local.efs.enabled
  efs_filesystems      = local.efs.filesystems
  efs_excluded_regions = local.efs.excluded_regions

  # --- efs regions
  # if the efs feature is not enabled, set efs_regions to an empty list, otherwise
  # it will adopt the global workbench regions.
  # if there are excluded regions specified, they will be removed from the final list of regions where 
  # efs filesystems are created. 
  efs_base    = local.efs_enabled ? var.workbench_regions : []
  efs_regions = setsubtract(local.efs_base, local.efs_excluded_regions)
}

# --- modules ---

module "efs" {
  source = "./modules/efs"

  for_each               = toset(local.efs_regions)
  region                 = each.value
  prefix                 = local.workbench_prefix
  efs_file_systems       = local.efs_filesystems
  max_availability_zones = var.max_availability_zones

  kms_key_id                 = module.kms[each.value].kms_key_arn
  vpc_id                     = module.vpc[each.value].vpc_id
  private_subnet_ids         = module.vpc[each.value].private_subnet_ids
  private_subnet_cidr_blocks = module.vpc[each.value].private_subnet_cidrs

  # tags
  resource_tags = local.resource_tags
  tags          = local.tags
}

module "efs_iam" {
  source = "./modules/efs-iam"

  for_each       = local.efs_enabled ? toset(["this"]) : toset([])
  account_id     = local.account_id
  prefix         = local.workbench_prefix
  sid_prefix     = local.sid_prefix
  principal_tags = local.principal_tags
  resource_tags  = local.resource_tags
  tags           = local.tags

  workspace_manager_role_name = local.workspace_manager_role_name

  efs_user_role_names = compact([
    local.workbench_user_role_name
  ])
}
