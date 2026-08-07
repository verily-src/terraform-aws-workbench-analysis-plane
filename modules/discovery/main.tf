
resource "aws_s3_bucket" "discovery" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    local.tags,
    { "Name" = local.bucket_name }
  )
}

resource "aws_s3_bucket_public_access_block" "discovery" {
  bucket = aws_s3_bucket.discovery.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "discovery" {
  bucket = aws_s3_bucket.discovery.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.discovery_bucket.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_versioning" "discovery" {
  bucket = aws_s3_bucket.discovery.id

  versioning_configuration {
    status = var.versioning
  }
}
