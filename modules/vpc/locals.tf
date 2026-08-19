locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-${replace(var.region, "-", "")}")

  # --- multi-az configuration
  # retrieve total count of all availability zones and use either the "max" or the 
  # user-specified number of AZs, whichever is lower. 
  # This allows us to automatically adjust to different regions with different numbers of AZs 
  # while still giving users control to limit the number of AZs for cost optimization if desired.
  az_count = var.max_availability_zones == "max" ? length(data.aws_availability_zones.available.names) : tonumber(var.max_availability_zones)

  # --- private subnet CIDR blocks
  private_subnet_cidrs = flatten([
    for i in range(local.az_count) : [
      # private subnet cidr blocks - creates /26 subnets (64 IPs each)
      i == 0 ? "10.0.1.0/24" : cidrsubnet("10.0.7.0/22", 4, i - 1),

      # private extended subnet cidr blocks
      i == 0 ? "10.0.192.0/18" : cidrsubnet("10.0.0.0/16", 4, i + 1)
    ]
  ])

  dns_log_count = var.vpc_dns_log_bucket != "" ? 1 : 0

  # --- tags
  # combine the user-provided tags with optional tags for all resources in this module.
  tags = merge(
    var.tags,
    {}
  )
}
