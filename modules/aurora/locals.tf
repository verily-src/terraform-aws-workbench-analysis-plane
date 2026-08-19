locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${replace(var.region, "-", "")}-aurora")

  # --- aurora postgres family
  # determine the aurora postgres family based on the major version number 
  # of the postgresql_version variable, which is used to set the engine family for the aurora cluster and aurora serverless v2 cluster resources. This allows us to support multiple major versions of aurora postgres while still using the same code for both, as the engine family is determined dynamically based on the postgresql_version variable.
  aurora_pg_family = "aurora-postgresql${split(".", var.postgresql_version)[0]}"

  # --- adjust auto_pause_seconds based on min_acu:
  # - If min_acu > 0, auto-pause doesn't work, so set to null regardless of what user specified
  # - If min_acu = 0, use the user's value (or the default of 3600)
  auto_pause_seconds = var.min_acu > 0 ? null : var.auto_pause_seconds

  # --- aurora availability zones cidrs
  # define a list of CIDR blocks for the aurora cluster subnets in each availability
  aurora_availability_zone_cidrs = [
    "10.0.188.0/23",
    "10.0.190.0/23"
  ]

  # --- performance insights retention period
  # this sets the performance insights retention period for the aurora clusters, in days. The
  performance_insights_enabled          = true
  performance_insights_retention_period = 465 # 15 months, required for advanced mode

  # --- restore point in time
  # this gets set if restore_to_point_in_time is present in the aurora features block
  restore_aurora = var.restore_to_point_in_time != null

  # --- tags
  # combine the user-provided tags with the default tags for all resources 
  # in this module.
  tags = merge(
    var.tags,
    {
      "Version"                  = local.aurora_pg_family
      (var.resource_tags.aurora) = "true"
    }
  )
}

# --- data resources ---

data "aws_availability_zones" "available" {
  region = var.region
}
