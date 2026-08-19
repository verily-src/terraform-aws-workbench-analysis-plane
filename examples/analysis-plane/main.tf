# --- data sources ---

data "aws_caller_identity" "current" {}

# --- modules ---

module "workbench_analysis_plane" {
  source  = "verily-src/workbench-analysis-plane/aws"
  version = "~> 0.3.12"

  # workbench main values
  deployment_id = local.deployment_id

  # account and environment values
  account_name   = local.account_name
  environment    = local.environment
  tenant         = local.tenant
  primary_region = local.aws_region

  # semver for tagging and discovery
  semver_version = local.semver_version

  # workbench regions
  workbench_regions = local.workbench_regions

  # option features configuration
  features = local.features

  # gcp oauth service account identifiers
  gcp_oauth_accounts = var.gcp_oauth_accounts

  # resource protection
  enable_resource_protection = local.enable_resource_protection

  # --- vcp flow log bucket
  # (optional) this is the bucket that VPC flow logs will be delivered to. 
  # it must already exist and be configured with the appropriate permissions. 
  vpc_flow_log_bucket_name = local.vpc_flow_log_bucket_name
}
