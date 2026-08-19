locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower(var.prefix)

  # --- workspace iam role names
  workspace_manager_role_name = "${local.prefix}-workspace-manager"
  workbench_user_role_name    = "${local.prefix}-workspace-user"

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {}
  )
}
