output "kms_user_policy_arn" {
  value = aws_iam_policy.kms_user.arn
}

output "kms_manager_policy_arn" {
  value = aws_iam_policy.kms_manager.arn
}

output "kms_user_policy_doc" {
  value = data.aws_iam_policy_document.kms_user.json
}
