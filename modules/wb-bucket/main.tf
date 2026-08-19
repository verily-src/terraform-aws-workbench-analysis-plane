resource "aws_s3_bucket" "default" {
  region        = var.region
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  // This block is required to avoid conflicting state results with aws_s3_bucket_cors_configuration
  // See https://registry.terraform.io/providers/hashicorp/aws/3.75.2/docs/resources/s3_bucket_cors_configuration#usage-notes
  lifecycle {
    ignore_changes = [
      cors_rule
    ]
  }

  tags = merge(local.tags, { "Name" = local.bucket_name })
}

resource "aws_s3_bucket_policy" "allow_only" {
  region = var.region
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.allow_only.json
}

resource "aws_s3_bucket_public_access_block" "default" {
  region = var.region
  bucket = aws_s3_bucket.default.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  region = var.region
  bucket = aws_s3_bucket.default.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_cors_configuration" "default" {
  # only create cors configuration if allowed_origins list is non-empty
  count  = length(var.allowed_origins) > 0 ? 1 : 0
  region = var.region
  bucket = aws_s3_bucket.default.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
  }
}

resource "aws_s3_bucket_versioning" "default" {
  count  = var.versioning != null ? 1 : 0
  region = var.region
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  count  = (var.noncurrent_version_max_count != null || var.noncurrent_version_expiration_days != null) ? 1 : 0
  region = var.region
  bucket = aws_s3_bucket.default.id

  rule {
    id     = "noncurrent-version-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      newer_noncurrent_versions = var.noncurrent_version_max_count
      noncurrent_days           = var.noncurrent_version_expiration_days
    }
  }

  lifecycle {
    precondition {
      condition     = var.versioning == "Enabled"
      error_message = "Lifecycle configuration for noncurrent versions requires versioning to be 'Enabled'."
    }
  }

  depends_on = [aws_s3_bucket_versioning.default]
}

# --- datasync config (optional and useful during migrations) ---

resource "aws_datasync_location_s3" "source" {
  for_each      = var.datasync_source_bucket_id != null ? toset(["this"]) : toset([])
  region        = var.region
  s3_bucket_arn = "arn:aws:s3:::${var.datasync_source_bucket_id}-${var.region}-workbench"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = var.datasync_iam_role_arn
  }
}

resource "aws_datasync_location_s3" "destination" {
  for_each      = var.datasync_source_bucket_id != null ? toset(["this"]) : toset([])
  region        = var.region
  s3_bucket_arn = "arn:aws:s3:::${aws_s3_bucket.default.bucket}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = var.datasync_iam_role_arn
  }
}

resource "aws_datasync_task" "sync" {
  for_each                 = var.datasync_source_bucket_id != null ? toset(["this"]) : toset([])
  region                   = var.region
  source_location_arn      = aws_datasync_location_s3.source["this"].arn
  destination_location_arn = aws_datasync_location_s3.destination["this"].arn
  name                     = "workbench-bucket-sync"

  schedule {
    schedule_expression = "rate(1 hour)"
  }

  options {
    overwrite_mode         = "ALWAYS"
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    posix_permissions      = "NONE"
    uid                    = "NONE"
    gid                    = "NONE"
  }
}
