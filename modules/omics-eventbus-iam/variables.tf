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

variable "bucket_name_prefix" {
  type        = string
  description = "The prefix to use for the S3 bucket ARNs in the IAM policies."
}

variable "workflow_manager_role_name" {
  type        = string
  description = "A string representing the role to create for the workflow manager."
}

variable "workflow_manager_role_arn" {
  type        = string
  description = "The ARN of the IAM role for the workflow manager."
}

variable "permission_boundary_policy_documents" {
  type        = list(string)
  description = "A list of JSON strings representing the source IAM policy documents to be used in the permission boundary."
}

variable "iam_denied_resources" {
  type        = list(string)
  description = "Bucket ID strings, with or without wildcards, that Workspace Manager and Workbench User roles should never have access to."
  default     = []
}

variable "execution_role_arn_pattern" {
  type        = string
  description = "The ARN pattern for the execution roles that are assumed by the Omics service when it executes tasks on behalf of the user."
}

variable "omics_log_group" {
  type        = string
  description = "The ARN of the CloudWatch Logs log group where the Omics service will write logs."
}

variable "resource_tags" {
  description = "A map of all resource tags to use in IAM polices and resources."
  type        = map(string)
}

variable "principal_tags" {
  type        = map(string)
  description = "The names of the principal tags to use in the IAM policies."
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
