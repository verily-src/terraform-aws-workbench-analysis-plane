locals {
  aws_account_id = "<aws_account_id>"   # replace with your AWS account ID
  account_name   = "<aws_account_name>" # replace with your AWS account name
  environment    = "<environment>"      # dev, stage, test, prod.
  tenant         = "<tenant/teamname>"  # upto 6 characters, lowercase, no special characters

  # --- aws region (primary) ---
  # this defaults to us-east-1, but can be set to another region if desired.
  aws_region = "<primary_aws_region>" # replace with your primary AWS region (e.g., us-east-1, us-west-2, etc.)

  # --- semantic version
  # this is used in the discovery payload and resource tagging.
  # IMPORTANT: this should match the version used for the vwb-analysis-plane module, prefixed with 'v.
  semver_version = "v0.3.20" # update this when needed

  # --- deployment_id
  # this ID should be 'main' for the primary workbench environment. If additional analysis planes need to be created
  # in the same AWS account, give this a meaningful name (limited to 6 chars). AWS resource will use this ID in their names.
  deployment_id = "main" # DO NOT CHANGE THIS VALUE!

  # --- resource protection
  # this flag is used to enable resource protection for the account. When enabled, certain resources will be protected from deletion or modification.
  # Prevents destroying Aurora Serverless clusters and buckets resources. Consider setting to true for production environments.
  enable_resource_protection = false

  # --- vpc flow log bucket
  # this bucket must already exist and be configured with the appropriate permissions for VPC flow logs to be delivered to it. 
  # it is not managed by Terraform in this module, but is passed as a variable to the vwb-analysis-plane module which creates 
  # the necessary resources to enable VPC flow logs to be delivered to it.
  # **leave blank, or specify an existing bucket name
  vpc_flow_log_bucket_name = ""
}
