variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "max_availability_zones" {
  description = "The maximum number of availability zones to use for the workbench resources."
  type        = string
  validation {
    condition     = can(regex("^([1-4]|max)$", var.max_availability_zones))
    error_message = "max_availability_zones must be between 1 and 4, or max."
  }
}

variable "vpc_flow_log_name" {
  type        = string
  description = "The name of the VPC flow log. This is for legacy environments that have hardcoded flow log names. New environments should leave this blank. The flowlog name will be the bucket name."
  default     = null
}

variable "vpc_flow_logs_bucket_name" {
  type        = string
  description = "The destination bucket for the VPC flow logs."
  default     = null
}

variable "additional_vpc_flow_logs_bucket_names" {
  type        = list(string)
  description = "Additional destination buckets for the VPC flow logs. Multiple flow logs will be created, one for the primary bucket and one for each additional bucket."
  default     = []
}

variable "vpc_flow_logs_enhanced_format_bucket_name" {
  type        = set(string)
  description = "Set of bucket names that should receive VPC flow logs with all available fields. If empty, all flow logs use the default format. Each bucket in this set must match either vpc_flow_logs_bucket_name or one of the additional_vpc_flow_logs_bucket_names."
  default     = []
}

variable "vpc_dns_log_bucket" {
  type        = string
  description = <<EOF
  S3 bucket for holding VPC DNS logs (Route53 resolver query logs).

  Optional. If this bucket is not provided, the VPC will not have query logging configured.
  EOF
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module. These tags will be merged with default tags and cannot overwrite the default 'Name' tag."
  default     = {}
}
