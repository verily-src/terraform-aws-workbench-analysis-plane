locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${var.account_id}-${replace(var.region, "-", "")}")

  # --- bucket name
  bucket_name = "${local.prefix}-workbench"

  # --- allowed ids
  allowed_userids = [
    for id in var.allowed_bucket_object_role_unique_ids : "${id}:*"
  ]

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {}
  )
}
