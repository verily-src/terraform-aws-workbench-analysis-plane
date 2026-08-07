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
  description = "The prefix to use for the SIDs in the IAM policies. This is used to ensure that the SIDs are unique across all policies in the account."
  default     = "Vwb"
}

variable "workspace_manager_role_arn" {
  type        = string
  description = "The ARN of the workspace manager role to grant permissions to in the IAM policies."
}

variable "principal_tags" {
  type        = map(any)
  description = "The names of the principal tags to use in the IAM policies."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
