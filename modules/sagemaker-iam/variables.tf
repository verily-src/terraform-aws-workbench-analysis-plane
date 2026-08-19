variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "workspace_manager_role_name" {
  type        = string
  description = "The name of the IAM role to attach the SageMaker manager policy to."
}

variable "workbench_user_role_name" {
  type        = string
  description = "The name of the IAM role to attach the SageMaker user policy to."
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
}
