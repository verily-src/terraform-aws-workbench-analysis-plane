output "external_access_role_arn" {
  value = aws_iam_role.external_access.arn
}

output "external_access_role_name" {
  value = aws_iam_role.external_access.name
}
