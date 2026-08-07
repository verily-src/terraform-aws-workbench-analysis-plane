locals {
  # --- kms key alias
  # construct the KMS key alias using the prefix, to ensure consistent naming and easy identification
  kms_key_name = "workspace-manager"

  # --- kms key alias from kms module output
  kms_key_alias = "${local.workbench_prefix}-${local.kms_key_name}"
}

# --- modules ---

# create the regional kms keys
module "kms" {
  source = "./modules/kms"

  for_each = toset(var.workbench_regions)
  region   = each.key
  name     = local.kms_key_alias
  tags     = local.tags
}

module "kms_iam" {
  source        = "./modules/kms-iam"
  account_id    = local.account_id
  prefix        = local.workbench_prefix
  sid_prefix    = local.sid_prefix
  kms_key_alias = local.kms_key_alias
  tags          = local.tags

  bucket_name_prefix          = local.bucket_name_prefix
  workspace_manager_role_name = local.workspace_manager_role_name

  kms_user_role_names = compact([
    local.workbench_user_role_name,
    local.omics_user_delegate_role_name
  ])
}
