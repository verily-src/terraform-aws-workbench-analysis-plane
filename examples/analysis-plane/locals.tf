locals {
  aws_account_id = "<aws_account_id>"   # replace with your AWS account ID
  account_name   = "<aws_account_name>" # replace with your AWS account name
  environment    = "<environment>"      # dev, stage, test, prod.
  system         = "workbench"          # DO NOT CHANGE THIS VALUE!
  tenant         = "<tenant/teamname>"  # upto 6 characters, lowercase, no special characters

  # --- aws region (primary) ---
  # this defaults to us-east-1, but can be set to another region if desired.
  aws_region = "<primary_aws_region>" # replace with your primary AWS region (e.g., us-east-1, us-west-2, etc.)

  # --- semantic version
  # this is used in the discovery payload and resource tagging.
  semver_version = "v0.3.3" # update this when needed

  # --- deployment_id
  # this ID should be 'main' for the primary workbench environment. If additional analysis planes need to be created
  # in the same AWS account, give this a meaningful name (limited to 6 chars). AWS resource will use this ID in their names.
  deployment_id = "main" # DO NOT CHANGE THIS VALUE!

  # --- workbench regions
  # this list specifies the regions where the infrastructure resources required for the Workbench
  # control plane will be deployed. The default is the list below.
  workbench_regions = [
    "us-east-1",
    "us-west-1",
    "us-west-2",
    "eu-west-2"
  ]

  # --- resource protection
  # this flag is used to enable resource protection for the account. When enabled, certain resources will be protected from deletion or modification.
  # Prevents destroying Aurora Serverless clusters and buckets resources. Consider setting to true for production environments.
  enable_resource_protection = false

  # --- vpc flow log bucket
  # this bucket must already exist and be configured with the appropriate permissions for VPC flow logs to be delivered to it. 
  # it is not managed by Terraform in this module, but is passed as a variable to the vwb-analysis-plane module which creates 
  # the necessary resources to enable VPC flow logs to be delivered to it.
  vpc_flow_log_bucket_name = "<leave blank, or specify an existing bucket name>"

  # --- analysis plane features
  # the excluded_regions lists can be used to specify regions where the respective feature should 
  # not be deployed.
  features = {
    aurora_serverless = {
      enabled            = true
      postgresql_version = "16.11"
      excluded_regions   = []
    }
    ecr_endpoints = {
      enabled          = false
      excluded_regions = []
    }
    s3_endpoints = {
      enabled          = true
      excluded_regions = []
    }
    omics = {
      enabled          = true
      excluded_regions = []
    }
    notebook = {
      enabled          = true
      excluded_regions = []
    }
  }
}
