# --- role outputs ---

output "user_delegate_role_name" {
  value       = aws_iam_role.omics_user_delegate.name
  description = "The name of the IAM role that the workflow manager will use to delegate permissions to users for accessing omics resources. This role is assumed by the workflow manager when it needs to perform actions on behalf of the users, such as accessing S3 buckets or KMS keys, using the permissions granted to this role."
}

output "user_delegate_role_arn" {
  value       = aws_iam_role.omics_user_delegate.arn
  description = "The ARN of the IAM role that the workflow manager will use to delegate permissions to users for accessing omics resources. This role is assumed by the workflow manager when it needs to perform actions on behalf of the users, such as accessing S3 buckets or KMS keys, using the permissions granted to this role."
}

output "user_delegate_role_unique_id" {
  value       = aws_iam_role.omics_user_delegate.unique_id
  description = "The unique ID of the IAM role that the workflow manager will use to delegate permissions to users for accessing omics resources. This is used in the S3 bucket policies to allow this role to access the buckets on behalf of the users."
}

# --- event bus outputs ---

output "event_bus_invoke_role_name" {
  value       = aws_iam_role.omics_events_bus_invoke.name
  description = "The name of the IAM role that allows EventBridge to invoke the Omics event bus. This role is assumed by EventBridge when it needs to put events on the Omics event bus, and it requires permissions to do so."
}

output "event_bus_invoke_role_arn" {
  description = "ARN of the IAM role for EventBridge to invoke Omics event bus"
  value       = aws_iam_role.omics_events_bus_invoke.arn
}

output "event_bus_arn" {
  description = "ARN of the event bus for omics events"
  value       = aws_cloudwatch_event_bus.omics_events.arn
}

# --- sqs outputs ---

output "sqs_events_queue_name" {
  description = "Name of the SQS queue for omics events"
  value       = aws_sqs_queue.omics_events.name
}

output "sqs_events_queue_url" {
  description = "URL of the SQS queue for omics events"
  value       = aws_sqs_queue.omics_events.url
}

output "event_rule_arn" {
  description = "The ARN of the CloudWatch Event rule for omics state changes."
  value       = aws_cloudwatch_event_rule.omics_state_changes.arn
}

# --- policy outputs ---

output "execution_permission_boundary_policy_arn" {
  description = "ARN of the IAM policy used as a permission boundary for omics execution roles"
  value       = aws_iam_policy.execution_permission_boundary.arn
}
