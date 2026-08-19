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

variable "aurora_master_username" {
  type        = string
  description = "The master username for the Aurora clusters. This is used to construct the resource ARNs in the IAM policies for Aurora access, and also to determine which database users can authenticate using IAM database authentication."
}

variable "aurora_user_role_names" {
  type        = list(string)
  description = "The names of the Aurora user roles."
}

variable "workspace_manager_role_name" {
  type        = string
  description = "The name of the workspace manager role."
}

variable "principal_tags" {
  type        = map(any)
  description = "The names of the principal tags to use in the IAM policies for Aurora access. The values of these tags will be used to construct the resource ARNs in the IAM policies for Aurora access. The principal tags must be passed in as variables to the workspace manager module, and then set on the IAM principals (users/roles) that need access to Aurora. The values of these tags on the IAM principals will determine which Aurora clusters and databases they can access, and whether they have read-only or read-write access."
}

variable "resource_tags" {
  type        = map(any)
  description = "The names of the resource tags to use in the IAM policies for Aurora and EFS access. The values of these tags will be used to construct conditions in the IAM policies for Aurora and EFS access, to ensure that the permissions only apply to the specific Aurora clusters and EFS file systems that are tagged with these tags. The resource tags must be passed in as variables to the workspace manager module, and then set on the Aurora clusters and EFS file systems that need to be accessed by the workspace manager. The values of these tags on the Aurora clusters and EFS file systems will determine which resources can be accessed by the workspace manager."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
