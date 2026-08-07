variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the bucket when it is deleted. If true, all objects in the bucket will be deleted when the bucket is destroyed. Use with caution."
  default     = false
}

variable "allowed_origins" {
  type        = list(string)
  description = "A list of allowed origins for CORS requests to S3 buckets."
  default     = []
}

variable "bucket_versioning" {
  type        = string
  description = <<-EOT
    Versioning status for the S3 bucket. Valid values: 'Enabled', 'Suspended', or null for no versioning.
    Once versioning has been 'Enabled' on a bucket, it can never be fully disabled - only 'Suspended'.
  EOT
  default     = "Enabled"

  validation {
    condition     = var.bucket_versioning == null || var.bucket_versioning == "Enabled" || var.bucket_versioning == "Suspended"
    error_message = "Bucket versioning must be 'Enabled', 'Suspended', or null."
  }
}

variable "bucket_noncurrent_version_max_count" {
  type        = number
  description = "Maximum number of noncurrent versions to retain. Only applies when bucket_versioning is 'Enabled'."
  default     = 2
}

variable "bucket_noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days after which noncurrent versions expire. Only applies when bucket_versioning is 'Enabled'."
  default     = 30
}

# --- protected buckets ---

variable "protected_buckets" {
  type        = list(string)
  description = "Bucket ID strings, with or without wildcards, that TerraWorkspaceManager and TerraUser roles should never have access to."
  default = [
    "verily-*-tf-*",
    "verily-macie-results-*",
    "*discovery",
  ]
}

# --- datasync ---

variable "bucket_datasync_source_bucket_id" {
  type        = string
  description = "The ID of the source bucket to replicate from. This should be the bucket name or ARN of an existing S3 bucket. If not provided, replication will not be configured for this bucket."
  default     = null
}

variable "bucket_datasync_iam_role_arn" {
  type        = string
  description = "The ARN of the IAM role to use for S3 replication. This role must already exist and be configured with the appropriate permissions. If not provided, replication will not be configured for this bucket."
  default     = null
}
