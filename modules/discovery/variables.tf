variable "account_id" {
  type        = string
  description = "The AWS account ID where the resources are provisioned."
}

variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "sid_prefix" {
  type        = string
  description = "The prefix to use for all IAM policy statement IDs created by this module."
}

variable "app_instance_role_arns" {
  type        = list(string)
  description = "A list of ARNs for the app_instance IAM roles."
}

variable "gcp_service_accounts" {
  type = object({
    aud = string
    sub = list(string)
  })
  description = "The GCP service account attributes to be used in the IAM policies. 'aud' is the audience claim that will be included in the JWTs issued for the GCP service accounts, and 'sub' is a list of subject claims (service account email addresses) that will be allowed to assume the IAM role."
}

# --- bucket  ---

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the bucket when it is deleted. If true, all objects in the bucket will be deleted when the bucket is destroyed. Use with caution."
  default     = false
}

variable "versioning" {
  type        = string
  description = <<-EOT
    Versioning status for the discovery bucket. Valid values: 'Enabled', 'Suspended', or null for no versioning.
    Once versioning has been 'Enabled' on a bucket, it can never be fully disabled - only 'Suspended'.
  EOT
  default     = "Enabled"

  validation {
    condition     = var.versioning == null || var.versioning == "Enabled" || var.versioning == "Suspended"
    error_message = "Versioning must be 'Enabled', 'Suspended', or null."
  }
}

# --- misc ---

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}

# --- regression testing inputs ---

variable "regression_testing_assume_role_arns" {
  description = "A list of ARNs for additional IAM roles to allow assuming, used for regression testing."
  type        = list(string)
}
