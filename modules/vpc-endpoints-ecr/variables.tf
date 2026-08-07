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

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC in which to create the ECR endpoints."
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet in which to create the ECR interface endpoints. This should be a private subnet in the VPC."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
