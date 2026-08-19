output "discovery_role_name" {
  description = "Name of the IAM role used for discovery"
  value       = aws_iam_role.discovery.name
}

output "discovery_role_arn" {
  description = "ARN of the IAM role used for discovery"
  value       = aws_iam_role.discovery.arn
}

output "discovery_bucket_name" {
  description = "Name of the S3 bucket used for discovery outputs"
  value       = aws_s3_bucket.discovery.id
}

output "discovery_bucket_versioning_id" {
  description = "ID of the S3 bucket versioning configuration for the discovery bucket"
  value       = aws_s3_bucket_versioning.discovery.id
}

output "discovery_bucket_kms_key_arn" {
  description = "ARN of the KMS key used for encrypting the discovery bucket"
  value       = aws_kms_key.discovery_bucket.arn
}

output "discovery_bucket_kms_key_id" {
  description = "ID of the KMS key used for encrypting the discovery bucket"
  value       = aws_kms_key.discovery_bucket.key_id
}

output "discovery_bucket_kms_key_alias" {
  description = "Alias of the KMS key used for encrypting the discovery bucket"
  value       = aws_kms_alias.default.name
}
