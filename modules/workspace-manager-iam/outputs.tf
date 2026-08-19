# --- iam role outputs ---

output "workbench_user_role_name" {
  value       = aws_iam_role.workbench_user.name
  description = "The Workbench user role name"
}

output "workbench_user_role_arn" {
  value       = aws_iam_role.workbench_user.arn
  description = "The Workbench user role ARN"
}

output "workbench_user_role_unique_id" {
  value       = aws_iam_role.workbench_user.unique_id
  description = "The unique ID of the Workbench Workspace User role, which is used for bucket policies to allow the role to access the landingzone buckets"
}

output "workspace_manager_role_name" {
  value       = aws_iam_role.workspace_manager.name
  description = "The Workbench Workspace Manager role name"
}

output "workspace_manager_role_arn" {
  value       = aws_iam_role.workspace_manager.arn
  description = "The Workbench Workspace Manager role ARN"
}

output "workspace_manager_role_unique_id" {
  value       = aws_iam_role.workspace_manager.unique_id
  description = "The unique ID of the Workbench Workspace Manager role, which is used for bucket policies to allow the role to access the landingzone buckets"
}
