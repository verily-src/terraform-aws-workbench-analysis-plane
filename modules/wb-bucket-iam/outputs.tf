output "s3_user_policy_arn" {
  value = aws_iam_policy.s3_user.arn
}

output "s3_manager_policy_arn" {
  value = aws_iam_policy.s3_manager.arn
}
