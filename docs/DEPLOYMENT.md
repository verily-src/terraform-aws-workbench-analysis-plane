# Workbench Analysis Plane Deployment Guide

## Overview

The Workbench Analysis Plane module (`vwb-analysis-plane`) provides a comprehensive AWS infrastructure solution for deploying Terra Workbench environments. This module creates and manages all necessary resources for running scientific workloads including compute, storage, networking, and security infrastructure across multiple AWS regions.

## Table of Contents

- [Prerequisites](#prerequisites)
- [AWS Account Requirements](#aws-account-requirements)
- [Deployment Steps](#deployment-steps)
- [Feature Configuration](#feature-configuration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

--------------------------------------------------------------------------------

## Prerequisites

### Required Tools

1. **Terraform** (>= 1.9.0)

NOTE: The module has been tested with Terraform version 1.15.x and this version is supported.

If you are deploying the Analysis Plane module from the command line you also need:

1. **AWS CLI** (>= 2.0)

### Required Access

- **AWS Account Access**: Administrator or equivalent permissions in the target AWS account
- **Terraform Backend**: S3 bucket for state management (if using remote state)

--------------------------------------------------------------------------------

## AWS Account Requirements

### IAM Permissions

The deployment requires an IAM role with permissions to create and manage the following AWS services:

- **Networking**: VPC, Subnets, Route Tables, Internet Gateways, NAT Gateways, VPC Endpoints, Security Groups
- **Compute**: EC2 instances, Launch Templates, Auto Scaling Groups, SageMaker
- **Storage**: S3 buckets, EFS file systems, RDS Aurora Serverless
- **Security**: KMS keys, IAM roles and policies, Secrets Manager
- **Monitoring**: CloudWatch, VPC Flow Logs, Route53 Resolver Query Logs

### Example IAM Role Configuration

For deployments, and if you want an IAM role separate from an existing deployment role you have, you'll need an existing IAM role:

```hcl
resource "aws_iam_role" "workbench_deployment_role" {
  name = "workbench-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::<atlantis-account-id>:role/workbench-deployment-role"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

For deployments, you can attach an Administrator access policy to the deployment role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

**Note:** This policy grants full Administrator access to all AWS services and resources. For production deployments, consider creating a more restrictive policy that includes only the specific permissions required.

#### S3 Bucket for Terraform State

- Replace the bucket name and bucket key values with the desired bucket and path for Terraform state.

**Configuration recommendations:**

- Versioning enabled
- Encryption enabled (AES-256 or KMS)
- Appropriate bucket policy for Terraform access

#### Workbench regions

The module defaults to a specific set of AWS regions to deploy its resources. If you want to change these default regions, see `deployment steps` for details.

NOTE: at this time Workbench supports the regions below:

- us-east-1
- us-west-1
- us-west-2
- eu-west-2

#### VPC Flow Logs (Optional)

There are two options for VPC flow logs:

1. No logging

2. If not already present create a central S3 bucket dedicated to VPC flow logs; update the variable `vpc_flow_log_bucket_name` in `locals.tf`; and ensure the flow log bucket has the correct permissions (see below)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::<flow-log-bucket-name>/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::<flow-log-bucket-name>"
    }
  ]
}
```

--------------------------------------------------------------------------------

## Deployment Steps

### Step 1: Create Terraform Files

The easiest method is to copy the `example/analysis-plane` directory to a location in your hierarchy for your infrastructure.

1. Adjust the necessary values in `locals.tf`:

```hcl
aws_account_id = "<aws_account_id>"      # replace with your AWS account ID
  aws_region     = "<primary_aws_region>"  # the default primary region for your AWS account
  account_name   = "<aws_account_name>"    # replace with your AWS account name
  environment    = "<environment>"         # dev, stage, test, prod.
  tenant         = "<tenant/teamname>"     # upto 5 characters, lowercase, no special characters
  semver_version = "<release version>"     # proper semantic version tag (vX.X.X)
```

#### Workbench regions

The module defaults to creating its resources in the regions:

```hcl
locals {
  workbench_regions:
    - us-east-1
    - us-west-1
    - us-west-2
    - eu-west-2
}
```

This variable is defined by default in `locals.tf`. As indicated above those are the regions supported by Workbench at this time. You can choose to limit the number of regions by removing one or more regions from the list.

NOTES:

- The regions above are specific to where the infractructure resources for Workbench are deployed. The Workbench platform itself includes region policy features that can be used to restrict usage on a per region bases.
- It is recommended to leave at least 2 regions enabled.
- Ensure that one of the selected regions is used in the field used for primary_aws_region.
- Adjust the necessary values in `settings.tf`:

```hcl
terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    bucket = "<state-bucket-name>"
    key    = "<state-path>/terraform.tfstate"
    region = "<primary-aws-region>"

    assume_role = {
      role_arn = "arn:aws:iam::<aws_account_id>:role/<deployment-role>"
    }
  }
}
```

1. Adjust the necessary values in the the `provider` block:

```hcl
provider "aws" {
  region = "<primary-aws-region>"

  assume_role {
    role_arn = "arn:aws:iam::<aws_account_id>:role/<deployment-role>"
  }
}
```

Do not change any of the other local variables!

### Step 1: Initialize Terraform

```bash
cd analysis-plane
terraform init
```

This will:

- Download the analysis plane module
- Initialize the S3 backend
- Download required provider plugins

### Step 2: Review the Plan

```bash
terraform plan
```

**Expected Resources:**

The plan will show creation of approximately 100-200 resources including:

- VPC and networking components (subnets, route tables, NAT gateways, etc.)
- IAM roles and policies
- KMS keys for encryption
- S3 buckets for discovery and storage
- EFS file systems for shared storage
- Security groups
- VPC endpoints (S3, ECR if enabled)
- Aurora Serverless database (if enabled)
- CloudWatch log groups
- Route53 resolver query logging (if configured)

**Review checklist:**

- ✅ Verify the correct AWS account ID is being used
- ✅ Check that the VPC flow log bucket exists (if applicable)
- ✅ Confirm resource naming follows your conventions
- ✅ Ensure all required features are enabled
- ✅ Verify tags are correct

### Step 3: Apply the Configuration

```bash
terraform apply
```

**Deployment timeline:**

- **Typical duration**: 15-20 minutes
- **VPC and networking**: 5-10 minutes
- **Databases and storage**: 5-10 minutes
- **Compute and endpoints**: 5-10 minutes

### Step 4: Save Outputs

Setting up the Workbench Control plane requires the ARN of the discovery role and the name of the discovery bucket. Terraform outputs two values for this:

- `discovery_role_arn`
- `discovery_bucket_name`

```bash
terraform output > outputs.txt
```

Save these outputs for reference and integration with the Workbench services.

--------------------------------------------------------------------------------

## Feature Configuration

As discussed above, the module defaults to creating its resources in a set of default regions. The feature configuration allows for excluding one or more regions in the `exluded_regions` list from individual resource groups.

It is recommended to leave at least 2 regions enabled.

### Aurora Serverless Database

Controls deployment of PostgreSQL database for Workspace Manager.

The aurora settings are specified per region and per cluster in a region. If you want to exclude deployment of aurora in a region, simply do not specify that region in the clusters map. Optionally, the postgresql_version can be specified per cluster, otherwise the global postgresql_version will be used.

```hcl
aurora_serverless = {
  enabled            = true
  postgresql_version = "16.11"
  clusters = {
    us-east-1 = {
      cluster-01 = { # identifier becomes vwb-main-useast1-aurora-cluster-01
      }
    }
    us-west-1 = {
      cluster-01 = { # identifier becomes vwb-main-uswest1-aurora-cluster-01
      }
    }
    us-west-2 = {
      cluster-01 = { # identifier becomes vwb-main-uswest2-aurora-cluster-01
      }
    }
    eu-west-2 = {
      cluster-01 = { # identifier becomes vwb-main-euwest2-aurora-cluster-01
      }
    }
  }
}
```

**When to enable:**

- Required for Terra Workspace Manager functionality
- Provides persistent storage for workspace metadata

**Cost impact:** Moderate (based on ACU usage)

### ECR VPC Endpoints

Controls creation of VPC endpoints for Amazon ECR:

```hcl
ecr_endpoints = {
  enabled          = false  # Enable/disable ECR endpoints
  excluded_regions = []     # Regions to skip
}
```

**When to enable:**

- If workloads pull container images from ECR
- Reduces data transfer costs for container pulls
- Improves security (traffic stays in VPC)

**Cost impact:** Low (~$7-10/month per AZ)

### S3 VPC Endpoints

Controls creation of VPC endpoints for Amazon S3:

```hcl
s3_endpoints = {
  enabled          = true   # Enable/disable S3 endpoints
  excluded_regions = []     # Regions to skip
}
```

**When to enable:**

- Recommended for all deployments
- Eliminates data transfer charges for S3 access
- Improves performance and security

**Cost impact:** None (Gateway endpoints are free)

### AWS HealthOmics

Controls enablement of AWS HealthOmics service integration:

```hcl
omics = {
  enabled          = true   # Enable/disable Omics
  excluded_regions = []     # Regions to skip
}
```

**When to enable:**

- For genomics and life sciences workloads
- When using HealthOmics workflows

**Cost impact:** Usage-based (no infrastructure cost)

### Jupyter Notebooks (SageMaker)

Controls deployment of SageMaker notebook infrastructure:

```hcl
notebook = {
  enabled          = true   # Enable/disable notebook support
  excluded_regions = []     # Regions to skip
}
```

**When to enable:**

- Required for Jupyter notebook workspaces
- Provides managed notebook environments

**Cost impact:** Usage-based (only when notebooks are running)

--------------------------------------------------------------------------------

## Troubleshooting

### Common Issues

#### Issue: "VPC Flow Log Bucket Not Found"

**Error:**

```
Error: bucket does not exist or you don't have permissions
```

**Solution:**

1. Verify the bucket exists
2. Check bucket permissions
3. Ensure bucket is in the same region or has appropriate cross-region permissions

#### Issue: "Module Not Found" / Git Authentication

**Error:**

```
Error: Failed to download module
Could not download module "workbench_analysis_plane"
```

**Solution:**

1. Check the module version/tag exists in the repository

#### Issue: "Insufficient Permissions"

**Error:**

```
Error: creating VPC: UnauthorizedOperation
```

**Solution:**

1. Verify your AWS credentials: `aws sts get-caller-identity`
2. Check IAM role permissions include required services
3. If using assume role, verify trust relationship is configured

#### Issue: "Resource Quota Exceeded"

**Error:**

```
Error: LimitExceededException: You have reached the limit for VPCs
```

**Solution:**

1. Check current usage: `aws ec2 describe-vpcs`
2. Request quota increase via AWS Service Quotas console
3. Consider deploying in a different region

--------------------------------------------------------------------------------

## Best Practices

### Security

1. **Resource Protection** for production environments:

The local variable enable_resource_proctection is by default set to false. Setting this to 'true' will prevent Terraform from being able to destroy the Aurora cluster(s) and Workbench Buckets.

For permanent production environments, it is recommended to set this value to 'true'.

```hcl
enable_resource_protection = true
```

1. **Use KMS encryption** for sensitive resources (enabled by default in module)

### Cost Optimization

1. **Disable unused features** to reduce infrastructure costs:

  ```hcl
  features = {
  aurora        = { enabled = false }  # if not using Aurora
  ecr_endpoints = { enabled = false }  # If not using ECR
  omics         = { enabled = false }  # If not using HealthOmics
  }
  ```

2. **Use `excluded_regions`** to limit multi-region deployments:

  ```hcl
  features = {
  aurora_serverless = {
  enabled          = true
  excluded_regions = ["us-west-1", "eu-west-2"]  # Only deploy in essential regions
  }
  }
  ```

--------------------------------------------------------------------------------

## Disaster Recovery

To restore Aurora PostgreSQL, a snapshot is restored to a new cluster. This process can be initiated by specifying the correct values under the `features.aurora_serverless.restore_to_point_in_time` key that is passed into the Analysis Plane Module.

Example:

hcl

```
features = {
  aurora_serverless = {
    enabled            = true
    excluded_regions   = []
    postgresql_version = "16.11"
    restore_to_point_in_time = {
      # optionally list the source_cluster_identifiers. If blank the current deployed clusters will be
      # used as source_clusters in each region
      #
      # IMPORTANT: if you specify a single region, you MUST specify all regions where a cluster is to be restored!!
      #
      # source_cluster_identifiers = {
      #   us-east-1 = "vwb-main-useast1-aurora-cluster"
      #   us-west-2 = "vwb-main-uswest2-aurora-cluster"
      # }
      restore_type               = "full-copy"

      # if you want a specific point in time, provide this value
      restore_to_time            = "2026-01-23T19:00:00Z"

      # if you want the latest snapshot to be restored, set this value to true
      use_latest_restorable_time = false
    }
  }
}
```

### Steps

1. Supply the necessary values under the `features.aurora_serverless.restore_to_point_in_time` key in the locals.tf file for your environment.
2. Apply the Terraform
3. Validate the aurora cluster and instances, suffixed with `-restored` are created
4. Validate the data
5. Delete the original source cluster from each region that was restored
6. From the AWS console rename the cluster and instances, dropping the `-restored` suffix
7. Use `terraform state mv` to move the restored cluster into the terraform state for the original clusters
8. Remove the `restore_to_point_in_time` block from the `features.aurora_serverless` key
9. Run `terraform plan` and you should have no changes

### NOTE

The restored cluster(s) are not included in the Discovery AVRO payload. It is important to follow the steps above so not to get mismatches between the payload and the cluster being targetted!

Typically, a restore operation would require quiescing the environment temporarily.
