locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${replace(var.region, "-", "")}-efs")

  # --- multi-az configuration
  # retrieve total count of all availability zones and use either the "max" or the 
  # user-specified number of AZs, whichever is lower. 
  # This allows us to automatically adjust to different regions with different numbers of AZs 
  # while still giving users control to limit the number of AZs for cost optimization if desired.
  az_count = var.max_availability_zones == "max" ? length(data.aws_availability_zones.available.names) : tonumber(var.max_availability_zones)

  # --- efs mount targets
  # create a flattened list of file system + AZ combinations for mount targets
  efs_mount_targets = flatten([
    for fs_name, fs_config in var.efs_file_systems : [
      for az_index in range(local.az_count) : {
        key       = "${fs_name}-az${az_index}"
        fs_name   = fs_name
        az_index  = az_index
        subnet_id = var.private_subnet_ids[az_index * 2]
      }
    ]
  ])

  # --- efs access points
  # create a flattened map of file system + access point combinations
  efs_access_points = merge([
    for fs_name, fs_config in var.efs_file_systems : {
      for ap_name, ap_config in fs_config.access_points : "${fs_name}/${ap_name}" => {
        fs_name         = fs_name
        ap_name         = ap_name
        posix_user      = ap_config.posix_user
        root_directory  = ap_config.root_directory
        additional_tags = ap_config.additional_tags
      }
    }
  ]...)

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {
      (var.resource_tags.efs) = "true"
    }
  )
}
