locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${var.account_id}-discovery")

  # --- bucket name
  bucket_name = local.prefix

  # --- kms key alias
  kms_key_alias = lower("${var.prefix}-discovery")

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {}
  )
}
