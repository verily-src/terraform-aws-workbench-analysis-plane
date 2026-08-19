variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which to create the ECR endpoints."
}

variable "route_table_id" {
  type        = string
  description = "The ID of the route table for the VPC in which to create the S3 endpoints."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
