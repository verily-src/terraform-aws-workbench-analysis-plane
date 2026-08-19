variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "sid_prefix" {
  type        = string
  description = "The prefix to use for the SIDs in the IAM policies. This is used to ensure that the SIDs are unique across all policies in the account."
  default     = "Vwb"
}

variable "workbench_user_role_name" {
  type        = string
  description = "The name of the IAM role to attach the app instance user policy to."
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

