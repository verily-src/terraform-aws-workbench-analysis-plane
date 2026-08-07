variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "sid_prefix" {
  type        = string
  description = "The prefix to use for the SIDs in the IAM policies. This is used to ensure that the SIDs are unique across all policies in the account."
  default     = "Vwb"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
  default     = {}
}
