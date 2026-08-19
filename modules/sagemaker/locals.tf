locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${replace(var.region, "-", "")}")

  # --- lifecycle configuration names 
  # consumers expect these to be ordered from oldest to newest.
  # lifecycle_configuration_names = ["v1", "v2", "v3", "v4", "v5", "v6"]
  lifecycle_configuration_names = sort([
    for file in fileset(path.module, "../../data/sagemaker/*/on-start.sh") : basename(dirname(file))
  ])

  # --- lifecycle configurations
  lifecycle_configurations = [
    for config_name in local.lifecycle_configuration_names : {
      name      = config_name
      on_create = "${path.module}/../../data/sagemaker/${config_name}/on-create.sh"
      on_start  = "${path.module}/../../data/sagemaker/${config_name}/on-start.sh"
    }
  ]

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {}
  )
}
