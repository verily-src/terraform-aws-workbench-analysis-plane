# --- locals ---
# bump version

locals {
  # --- notebook features
  # this extracts the notebook serverless feature configuration from the features variable. 
  notebook = try(var.features.notebook, {
    enabled = false
  })

  # --- notebook role from the notebook_iam module
  # note that this is an output value from the module!
  notebook_role_arn = local.notebook.enabled ? module.notebook_iam["this"].notebook_role_arn : ""
}

# --- modules ---

module "notebook_iam" {
  source     = "./modules/notebook-iam"
  for_each   = local.notebook.enabled ? toset(["this"]) : toset([])
  prefix     = local.workbench_prefix
  sid_prefix = local.sid_prefix
  tags       = local.tags
}
