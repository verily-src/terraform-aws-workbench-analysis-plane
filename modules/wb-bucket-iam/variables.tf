variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "sid_prefix" {
  type        = string
  description = "The prefix to use for the SIDs in the IAM policies. This is used to ensure that the SIDs are unique across all policies in the account."
  default     = "Vwb"
}

variable "iam_denied_resources" {
  type        = list(string)
  description = "Bucket ID strings, with or without wildcards, that Workspace Manager and Workbench User roles should never have access to."
  default     = []
}

variable "bucket_name_prefix" {
  type        = string
  description = "The prefix of the S3 bucket names that the IAM policies should reference in the conditions to ensure that the permissions only apply to the specific S3 buckets that are used in the workbench."
}

variable "workspace_manager_role_name" {
  type        = string
  description = "The name of the role to create for the workspace manager policies."
}

variable "s3_user_role_names" {
  type        = list(string)
  description = "A list of strings representing the role assignments to create for the s3 user policies."
}

variable "principal_tags" {
  type        = map(string)
  description = "The names of the principal tags to use in the IAM policies."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
