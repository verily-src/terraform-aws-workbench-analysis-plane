output "bucket_id" {
  value       = aws_s3_bucket.default.id
  description = "Analysis Plane's S3 Bucket ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.default.arn
  description = "Analysis Plane's S3 Bucket ARN"
}
