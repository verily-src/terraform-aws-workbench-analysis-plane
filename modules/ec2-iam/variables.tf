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
  description = "The name of the IAM role."
}

variable "workbench_user_role_name" {
  type        = string
  description = "The name of the workbench IAM role."
}

variable "app_instance_role_name" {
  type        = string
  description = "The name of the IAM role to attach the Application Framework Instance policies to."
}

variable "app_instance_role_arn" {
  type        = string
  description = "The ARN of the IAM role to attach the Application Framework Instance policies to."
}

variable "app_instance_role_unique_id" {
  type        = string
  description = "The unique ID of the IAM role to attach the Application Framework Instance policies to. This is used in the condition of the policy to ensure that only this specific role can be passed."
}

variable "axon_server_role_name" {
  type        = string
  description = "The name of the IAM role to attach the Axon Server policies to."
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
