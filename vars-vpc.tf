variable "vpc_flow_log_name" {
  type        = string
  description = "The name of the VPC flow log. This is for legacy environments that have hardcoded flow log names. New environments should leave this blank. The flowlog name will be the bucket name."
  default     = null
}

variable "vpc_flow_log_bucket_name" {
  description = "The name of the S3 bucket to store VPC flow logs in. This bucket must already exist and be configured with the appropriate permissions for VPC flow logs to be delivered to it."
  type        = string
  default     = null
}

variable "vpc_dns_log_bucket" {
  type        = string
  description = <<EOF
  S3 bucket for holding VPC DNS logs (Route53 resolver query logs).

  Optional. If this bucket is not provided, the VPC will not have query logging configured.
  EOF
  default     = ""
}
