variable "name" {
  type        = string
  description = "The name to use for all resources created by this module. This will be combined with the prefix to create the final name for each resource."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
