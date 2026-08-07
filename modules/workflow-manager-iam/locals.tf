locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = "${var.prefix}-workflow"

  # --- workflow iam role names
  workflow_manager_role_name = "${local.prefix}-manager"

  tags = merge(
    var.tags,
    {}
  )
}
