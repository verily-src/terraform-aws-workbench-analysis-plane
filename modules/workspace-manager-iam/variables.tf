variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}

# --- gcp service accounts --- 

variable "workspace_manager_gcp_service_account" {
  type = object({
    aud = string
    sub = string
  })
  description = "The JWT attributes from the WSM GCP service account."
}

# --- regression testing inputs ---

variable "regression_testing_assume_role_arns" {
  description = "A list of ARNs for additional IAM roles to allow assuming, used for regression testing."
  type        = list(string)
}
