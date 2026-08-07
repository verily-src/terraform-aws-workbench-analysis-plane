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

variable "workspace_manager_role_name" {
  type        = string
  description = "A string representing the role assignment to create for the workspace manager."
}

variable "efs_user_role_names" {
  type        = list(string)
  description = "The names of the EFS user roles."
}

variable "principal_tags" {
  type        = map(any)
  description = "The names of the principal tags to use in the IAM policies."
}

variable "resource_tags" {
  type        = map(any)
  description = "The names of the resource tags to use in the IAM policies."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
