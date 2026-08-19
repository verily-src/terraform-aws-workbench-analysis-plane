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

variable "kms_key_alias" {
  type        = string
  description = "The alias of the KMS key that the IAM policies should reference in the conditions to ensure that the permissions only apply to the specific KMS key that is used for encrypting the S3 buckets in the workbench. This is used to construct conditions in the IAM policies for KMS access, to ensure that the permissions only apply to the specific KMS key that is used for encrypting the S3 buckets in the workbench. The KMS key alias must be passed in as a variable to the workspace manager module, and then set on the KMS key that is created in the Landing Zone for encrypting the S3 buckets in the workbench."
}

variable "bucket_name_prefix" {
  type        = string
  description = "The prefix of the S3 bucket names that the IAM policies should reference in the conditions to ensure that the permissions only apply to the specific S3 buckets that are used in the workbench. This is used to construct conditions in the IAM policies for KMS access, to ensure that the permissions only apply to the specific S3 buckets that are used in the workbench. The S3 bucket name prefix must be passed in as a variable to the workspace manager module, and then used as a prefix for the names of the S3 buckets that are created in the workbench."
}

variable "workspace_manager_role_name" {
  type        = string
  description = "The name of the workspace managerrole assignment to create for the KMS manager policies."
}

variable "kms_user_role_names" {
  type        = list(string)
  description = "A list of strings representing the role assignments to create for the KMS user policies."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
