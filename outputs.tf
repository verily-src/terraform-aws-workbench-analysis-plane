# --- avro schemas and payloads ---

output "workbench_global_content" {
  description = "Content for the global workbench S3 object, containing the schema and payload information for the global workbench data structure"
  value = nonsensitive({
    payload = local.workbench_global_payload
    schema  = local.workbench_global_schema
  })
}

output "workbench_regional_content" {
  description = "Content for the regional workbench S3 object, containing the schema and payload information for the regional workbench data structure"
  value = nonsensitive({
    payload = local.workbench_regional_payload
    schema  = local.workbench_regional_schema
  })
}

# --- discovery outputs ---

output "discovery_role_arn" {
  description = "ARN of the IAM role used for discovery"
  value       = module.discovery_bucket.discovery_role_arn
}

output "discovery_bucket_name" {
  description = "Name of the S3 bucket used for discovery outputs"
  value       = module.discovery_bucket.discovery_bucket_name
}
