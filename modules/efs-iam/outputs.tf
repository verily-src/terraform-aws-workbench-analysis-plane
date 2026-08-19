output "efs_user_policy_arn" {
  value = aws_iam_policy.efs_user.arn
}

output "efs_workspace_manager_policy_arn" {
  value = aws_iam_policy.efs_workspace_manager.arn
}
