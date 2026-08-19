variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module."
}
