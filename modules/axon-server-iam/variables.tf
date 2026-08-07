variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "axon_server_gcp_service_account" {
  type = object({
    aud = string
    sub = string
  })
  description = "The JWT attributes from the Axon Server GCP service account."
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module. This can be used to add additional metadata to resources for organization, cost tracking, etc."
  type        = map(string)
  default     = {}
}
