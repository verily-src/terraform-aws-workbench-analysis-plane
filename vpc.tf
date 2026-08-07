locals {
  # --- vpc endpoint features
  # this extracts the vpc endpoint feature configuration from the features variable.
  ecr_endpoints = try(var.features.ecr_endpoints, {
    enabled          = false
    excluded_regions = []
  })

  s3_endpoints = try(var.features.s3_endpoints, {
    enabled          = false
    excluded_regions = []
  })

  # --- ecr endpoint regions
  # if the ecr endpoint feature is not enabled, set ecr_endpoint_regions to an empty list, otherwise
  # it will adopt the global workbench regions.
  # if there are excluded regions specified, they will be removed from the final list of regions where 
  # ecr endpoints are created. 
  ecr_endpoint_base    = local.ecr_endpoints.enabled ? var.workbench_regions : []
  ecr_endpoint_regions = setsubtract(local.ecr_endpoint_base, local.ecr_endpoints.excluded_regions)

  # --- s3 endpoint regions
  # if the s3 endpoint feature is not enabled, set s3_endpoint_regions to an empty list, otherwise
  # it will adopt the global workbench regions.
  # if there are excluded regions specified, they will be removed from the final list of regions where
  # s3 endpoints are created.
  s3_endpoint_base    = local.s3_endpoints.enabled ? var.workbench_regions : []
  s3_endpoint_regions = setsubtract(local.s3_endpoint_base, local.s3_endpoints.excluded_regions)
}

# --- modules ---

module "vpc" {
  source   = "./modules/vpc"
  for_each = toset(var.workbench_regions)
  region   = each.value
  prefix   = local.workbench_prefix
  tags     = local.tags

  vpc_flow_log_name         = var.vpc_flow_log_name
  vpc_flow_logs_bucket_name = var.vpc_flow_log_bucket_name
  vpc_dns_log_bucket        = var.vpc_dns_log_bucket
  max_availability_zones    = var.max_availability_zones
}

module "vpc_endpoints_ecr" {
  source         = "./modules/vpc-endpoints-ecr"
  for_each       = toset(local.ecr_endpoint_regions)
  region         = each.value
  prefix         = local.workbench_prefix
  vpc_id         = module.vpc[each.value].vpc_id
  vpc_cidr_block = module.vpc[each.value].vpc_cidr_block
  subnet_id      = module.vpc[each.value].private_subnet_ids[1] # AZ0, subnet 1
  tags           = local.tags
}

module "s3_endpoints" {
  source         = "./modules/vpc-endpoints-s3"
  for_each       = toset(local.s3_endpoint_regions)
  region         = each.value
  prefix         = local.workbench_prefix
  vpc_id         = module.vpc[each.value].vpc_id
  route_table_id = module.vpc[each.value].private_route_table_id
  tags           = local.tags
}
