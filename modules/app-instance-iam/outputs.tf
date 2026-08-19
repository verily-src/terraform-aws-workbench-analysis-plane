output "app_instance_role_arn" {
  description = "ARN of the app instance IAM role"
  value       = aws_iam_role.app_instance.arn
}

output "app_instance_role_name" {
  description = "Name of the app instance IAM role"
  value       = aws_iam_role.app_instance.name
}

output "app_instance_unique_id" {
  description = "Unique ID of the app instance IAM role"
  value       = aws_iam_role.app_instance.unique_id
}

output "app_instance_instance_profile_name" {
  description = "Name of the app instance IAM instance profile"
  value       = aws_iam_instance_profile.app_instance.name
}
