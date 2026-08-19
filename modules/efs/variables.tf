variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "sid_prefix" {
  type        = string
  description = "The prefix to use for the SIDs in the IAM policies. This is used to ensure that the SIDs are unique across all policies in the account."
  default     = "Vwb"
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "resource_tags" {
  type        = map(any)
  description = "The names of the resource tags to use in the IAM policies."
}

variable "max_availability_zones" {
  description = "The maximum number of availability zones to use for the workbench resources. This is used to limit the number of AZs that are used for the aurora cluster and aurora serverless v2 cluster resources, as well as for the VPC subnets. This can help to reduce costs while still providing high availability."
  type        = string
  validation {
    condition     = can(regex("^([1-4]|max)$", var.max_availability_zones))
    error_message = "max_availability_zones must be between 1 and 4, or max."
  }
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which to create the EFS file system and mount targets."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of IDs of the private subnets in which to create the EFS mount targets. There should be at least one subnet in each availability zone used by the workbench resources."
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "A list of CIDR blocks to use for the private subnets"
}

variable "kms_key_id" {
  type        = string
  description = "The ARN of the KMS key to use for encrypting the EFS file system. This should be the ARN of the KMS key created in the KMS module."
}

variable "efs_file_systems" {
  type = map(object({
    # Performance configuration
    performance_mode = optional(string, "generalPurpose") # generalPurpose or maxIO
    throughput_mode  = optional(string, "elastic")        # bursting, elastic, or provisioned

    # Lifecycle policy for transitioning to Infrequent Access storage
    # Valid values: AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS
    transition_to_ia = optional(string, "AFTER_30_DAYS")

    # Additional tags to add to the file system
    additional_tags = optional(map(string), {})

    # Access points to create on this file system
    access_points = optional(map(object({
      # POSIX user identity enforced for all file system requests through this access point
      posix_user = optional(object({
        uid            = number                     # POSIX user ID
        gid            = number                     # POSIX group ID
        secondary_gids = optional(list(number), []) # Secondary group IDs
      }), null)

      # Root directory configuration
      root_directory = optional(object({
        # Path on the EFS file system to expose as the root directory
        path = optional(string, "/")

        # Creation info - only used if the path doesn't exist and needs to be created
        creation_info = optional(object({
          owner_uid   = number # POSIX user ID for the directory owner
          owner_gid   = number # POSIX group ID for the directory owner
          permissions = string # POSIX permissions (e.g., "755")
        }), null)
      }), null)

      # Additional tags to add to the access point
      additional_tags = optional(map(string), {})
    })), {})
  }))
  description = "A map of EFS file system identifiers to be used by the landing zone."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
