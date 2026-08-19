output "aurora_user_actions_policy_arn" {
  value = aws_iam_policy.aurora_user_actions.arn
}

output "aurora_manager_policy_arn" {
  value = aws_iam_policy.aurora_manager.arn
}
