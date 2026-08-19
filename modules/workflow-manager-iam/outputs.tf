output "workflow_manager_role_arn" {
  description = "The ARN of the IAM role created for the workflow manager."
  value       = aws_iam_role.workflow_manager.arn
}

output "workflow_manager_role_name" {
  description = "The name of the IAM role created for the workflow manager."
  value       = aws_iam_role.workflow_manager.name
}
