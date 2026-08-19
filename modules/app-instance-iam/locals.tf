locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-app-instance")

  # --- app-instance iam role name
  app_instance_role_name = local.prefix

  tags = merge(
    var.tags,
    {}
  )
}
