terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    bucket = "<terraform_state_bucket_name>"
    key    = "<terraform_state_key>"
    region = "<terraform_state_region>"

    assume_role = {
      role_arn = "arn:aws:iam::<aws_account_id>:role/<deployment_role_name>"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "<primary_aws_region>"

  assume_role {
    role_arn = "arn:aws:iam::<aws_account_id>:role/<deployment_role_name>"
  }
  default_tags {
    tags = {
      Account            = local.account_name
      AccountID          = local.aws_account_id
      Environment        = local.environment
      ManagedBy          = "Terraform"
      Tenant             = local.tenant
      DeploymentID       = local.deployment_id
      WorkbenchDiscovery = "true"
    }
  }
}
