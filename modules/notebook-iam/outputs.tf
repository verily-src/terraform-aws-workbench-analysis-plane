output "notebook_role_arn" {
  description = "ARN of the notebook IAM role"
  value       = aws_iam_role.notebook.arn
}

output "notebook_role_name" {
  description = "Name of the notebook IAM role"
  value       = aws_iam_role.notebook.name
}
