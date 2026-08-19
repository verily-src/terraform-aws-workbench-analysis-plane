locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-notebook")

  # --- notebook iam role name
  notebook_role_name = "${local.prefix}-execution"

  tags = merge(
    var.tags,
    {}
  )
}
