locals {
  # --- bucket name prefix
  # construct the prefix for the S3 bucket names using the prefix
  bucket_name_prefix = lower("${local.workbench_prefix}-${local.account_id}")

  # --- allowed bucket object role unique ids
  # this is a list of unique ids that are allowed to be used in the bucket/object
  allowed_bucket_object_role_unique_ids = [
    local.workbench_user_unique_id,
    local.workspace_manager_unique_id,
    local.omics_user_delegate_unique_id,
    local.app_instance_unique_id
  ]
}

# --- modules ---

module "workbench_bucket" {
  source        = "./modules/wb-bucket"
  for_each      = toset(var.workbench_regions)
  region        = each.key
  account_id    = local.account_id
  prefix        = local.workbench_prefix
  force_destroy = (length(var.regression_testing_assume_role_arns) > 0 || var.enable_resource_protection == false) ? true : var.force_destroy

  versioning                         = var.bucket_versioning
  noncurrent_version_expiration_days = var.bucket_noncurrent_version_expiration_days
  noncurrent_version_max_count       = var.bucket_noncurrent_version_max_count

  kms_key_id                                = module.kms[each.key].kms_key_arn
  allowed_origins                           = var.allowed_origins
  allowed_bucket_object_role_principal_arns = [local.execution_role_arn_pattern]
  allowed_bucket_object_role_unique_ids     = local.allowed_bucket_object_role_unique_ids

  # optional datasync
  datasync_iam_role_arn     = var.bucket_datasync_iam_role_arn != null ? var.bucket_datasync_iam_role_arn : null
  datasync_source_bucket_id = var.bucket_datasync_source_bucket_id != null ? var.bucket_datasync_source_bucket_id : null

  # tags
  tags = local.tags
}

module "workbench_bucket_iam" {
  source               = "./modules/wb-bucket-iam"
  prefix               = local.workbench_prefix
  sid_prefix           = local.sid_prefix
  iam_denied_resources = local.iam_denied_resources
  bucket_name_prefix   = local.bucket_name_prefix

  workspace_manager_role_name = local.workspace_manager_role_name

  s3_user_role_names = compact([
    local.omics_user_delegate_role_name,
    local.workbench_user_role_name,
    local.app_instance_role_name
  ])

  # tags
  principal_tags = local.principal_tags
  tags           = local.tags
}
