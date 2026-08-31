# Workbench Analysis Plane Module

📖 **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete step-by-step deployment instructions

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | >= 4.45 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_name | The name of the AWS account. This is used for naming resources and for display purposes. | `string` | n/a | yes |
| allowed\_origins | A list of allowed origins for CORS requests to S3 buckets. | `list(string)` | `[]` | no |
| bucket\_datasync\_iam\_role\_arn | The ARN of the IAM role to use for S3 replication. This role must already exist and be configured with the appropriate permissions. If not provided, replication will not be configured for this bucket. | `string` | `null` | no |
| bucket\_datasync\_source\_bucket\_id | The ID of the source bucket to replicate from. This should be the bucket name or ARN of an existing S3 bucket. If not provided, replication will not be configured for this bucket. | `string` | `null` | no |
| bucket\_noncurrent\_version\_expiration\_days | Number of days after which noncurrent versions expire. Only applies when bucket\_versioning is 'Enabled'. | `number` | `30` | no |
| bucket\_noncurrent\_version\_max\_count | Maximum number of noncurrent versions to retain. Only applies when bucket\_versioning is 'Enabled'. | `number` | `2` | no |
| bucket\_versioning | Versioning status for the S3 bucket. Valid values: 'Enabled', 'Suspended', or null for no versioning.<br>Once versioning has been 'Enabled' on a bucket, it can never be fully disabled - only 'Suspended'. | `string` | `"Enabled"` | no |
| deployment\_id | The workbench id to use for naming resources. This should be unique across the organization. | `string` | `"main"` | no |
| enable\_resource\_protection | Whether to enable resource protection for buckets e.a. resources | `bool` | `true` | no |
| environment | The environment that this workbench is being deployed for. This is used for tagging and naming purposes. | `string` | n/a | yes |
| features | A map of features to enable or disable for the workbench. Each feature can have its own set of variables and configurations. This is used to conditionally create resources based on the features that are enabled. | `any` | `{}` | no |
| force\_destroy | Whether to force destroy the bucket when it is deleted. If true, all objects in the bucket will be deleted when the bucket is destroyed. Use with caution. | `bool` | `false` | no |
| gcp\_oauth\_accounts | n/a | <pre>map(object({<br>    oauth = object({<br>      audience = string<br>      ids = object({<br>        authnz            = string<br>        axon_server       = string<br>        workspace_manager = string<br>        workflow_manager  = string<br>      })<br>    })<br>  }))</pre> | n/a | yes |
| max\_availability\_zones | The maximum number of availability zones to use for the workbench resources. | `string` | `"max"` | no |
| primary\_region | The primary AWS region for the workbench. This is used for naming resources and for display purposes. It is also used as the default region for resources that do not have a region specified. | `string` | `"us-east-1"` | no |
| protected\_buckets | Bucket ID strings, with or without wildcards, that TerraWorkspaceManager and TerraUser roles should never have access to. | `list(string)` | <pre>[<br>  "verily-*-tf-*",<br>  "verily-macie-results-*",<br>  "*discovery"<br>]</pre> | no |
| regression\_testing\_assume\_role\_arns | A list of ARNs for additional IAM roles to allow assuming, used for regression testing. | `list(string)` | `[]` | no |
| semver\_version | The semantic version of the workbench. This is used for tagging and naming purposes. It should be in the format of major.minor.patch (e.g. 1.0.0). | `string` | n/a | yes |
| tags | A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag. | `map(string)` | `{}` | no |
| tenant | The tenant that this workbench is being deployed for. This is used for tagging and naming purposes. | `string` | n/a | yes |
| vpc\_dns\_log\_bucket | S3 bucket for holding VPC DNS logs (Route53 resolver query logs).<br><br>  Optional. If this bucket is not provided, the VPC will not have query logging configured. | `string` | `""` | no |
| vpc\_flow\_log\_bucket\_name | The name of the S3 bucket to store VPC flow logs in. This bucket must already exist and be configured with the appropriate permissions for VPC flow logs to be delivered to it. | `string` | `null` | no |
| vpc\_flow\_log\_name | The name of the VPC flow log. This is for legacy environments that have hardcoded flow log names. New environments should leave this blank. The flowlog name will be the bucket name. | `string` | `null` | no |
| workbench\_regions | The AWS regions to deploy the workbench resources in. | `list(string)` | <pre>[<br>  "us-east-1",<br>  "us-west-1",<br>  "us-west-2",<br>  "eu-west-2"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| discovery\_bucket\_name | Name of the S3 bucket used for discovery outputs |
| discovery\_role\_arn | ARN of the IAM role used for discovery |
| workbench\_global\_content | Content for the global workbench S3 object, containing the schema and payload information for the global workbench data structure |
| workbench\_regional\_content | Content for the regional workbench S3 object, containing the schema and payload information for the regional workbench data structure |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
