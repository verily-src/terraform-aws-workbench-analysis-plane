variable "account_id" {
  type        = string
  description = "The AWS account ID to filter events for. This ensures the EventBridge rule only captures events from the specified account."
}

variable "prefix" {
  type        = string
  description = "The prefix to use for all resources created by this module."
}

variable "region" {
  type        = string
  description = "The AWS region to create resources in."
}

variable "events_bus_arn" {
  description = "The ARN of the EventBridge event bus to send events to."
  type        = string
}

variable "bus_invoke_role_arn" {
  description = "The ARN of the IAM role for EventBridge to invoke Omics event bus."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module. This can be used to add additional metadata to resources for organization, cost tracking, etc."
  type        = map(string)
  default     = {}
}
