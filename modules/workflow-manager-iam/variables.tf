variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "workflow_manager_gcp_service_account" {
  type = object({
    aud = string
    sub = string
  })
  description = "The JWT attributes from the WFM GCP service account."
}

# --- tags ---

variable "tags" {
  description = "A map of tags to apply to all resources created by this module. This can be used to add additional metadata to resources for organization, cost tracking, etc."
  type        = map(string)
  default     = {}
}

# --- regression testing inputs ---

variable "regression_testing_assume_role_arns" {
  description = "A list of ARNs for additional IAM roles to allow assuming, used for regression testing."
  type        = list(string)
}

