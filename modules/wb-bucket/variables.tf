variable "account_id" {
  type        = string
  description = "The AWS account ID where the resources are provisioned."
}

variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the bucket when it is deleted. If true, all objects in the bucket will be deleted when the bucket is destroyed. Use with caution."
}

variable "allowed_origins" {
  type        = list(string)
  description = "A list of allowed origins for CORS requests to S3 buckets."
}

variable "allowed_bucket_object_role_unique_ids" {
  type        = list(string)
  description = "The unique role IDs which require access to the bucket objects"
}

variable "allowed_bucket_object_role_principal_arns" {
  type        = list(string)
  description = "The Principal ARNs or ARN patterns which require access to the bucket objects"
}

# --- bucket versioning ---

variable "versioning" {
  type        = string
  description = <<-EOT
    Versioning status for the S3 bucket. Valid values: 'Enabled', 'Suspended', or null for no versioning.
    Once versioning has been 'Enabled' on a bucket, it can never be fully disabled - only 'Suspended'.
  EOT
  default     = null

  validation {
    condition     = var.versioning == null || var.versioning == "Enabled" || var.versioning == "Suspended"
    error_message = "Versioning must be 'Enabled', 'Suspended', or null."
  }
}

variable "noncurrent_version_max_count" {
  type        = number
  description = "Maximum number of noncurrent versions to retain. Only applies when versioning is 'Enabled'."
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days after which noncurrent versions expire. Only applies when versioning is 'Enabled'."
}

# --- datasync ---

variable "datasync_source_bucket_id" {
  type        = string
  description = "The ID of the source bucket to replicate from. This should be the bucket name or ARN of an existing S3 bucket. If not provided, replication will not be configured for this bucket."
  default     = null
}

variable "datasync_iam_role_arn" {
  type        = string
  description = "The ARN of the IAM role to use for S3 replication. This role must have the necessary permissions to replicate objects from the source bucket to this bucket. If datasync_source_bucket_id is provided, this variable must also be provided."
  default     = null
}

# --- misc ---

variable "kms_key_id" {
  type        = string
  description = "The KMS key ID to use for encrypting the bucket. This can be the full ARN, the key ID, or the alias name of the KMS key. If not provided, the bucket will be encrypted with the default S3 encryption."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
