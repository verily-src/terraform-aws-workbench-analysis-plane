output "discovery_role_arn" {
  description = "ARN of the IAM role used for discovery"
  value       = module.workbench_analysis_plane_main.discovery_role_arn
}

output "discovery_bucket_name" {
  description = "Name of the S3 bucket used for discovery outputs"
  value       = module.workbench_analysis_plane.discovery_bucket_name
}
