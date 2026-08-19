# IAM - Permission Boundary for Omics Execution Roles created by the Workflow Manager.

resource "aws_iam_policy" "execution_permission_boundary" {
  name   = "${var.prefix}-execution-boundary"
  policy = data.aws_iam_policy_document.execution_permission_boundary.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-execution-boundary" })
}

# --- policy documents ---

data "aws_iam_policy_document" "execution_permission_boundary" {
  source_policy_documents = var.permission_boundary_policy_documents

  statement {
    sid       = "${var.sid_prefix}S3BucketAccess"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.bucket_name_prefix}*"]
  }

  statement {
    sid    = "${var.sid_prefix}S3ExternalAccess"
    effect = "Allow"
    actions = [
      "s3:Describe*",
      "s3:Get*",
      "s3:List*",
      "s3:DeleteObject",
      "s3:PutObject*"
    ]
    resources = ["arn:aws:s3:::*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:ResourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid       = "${var.sid_prefix}LogsAccess"
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = [var.omics_log_group]
  }

  statement {
    sid    = "${var.sid_prefix}ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "${var.sid_prefix}DenyS3ProtectedActions"
    effect = "Deny"
    actions = [
      "s3:DeleteAccess*",
      "s3:DeleteBucket*",
      "s3:DeleteObjectTagging",
      "s3:PutBucket*"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "${var.sid_prefix}DenyS3AccessProtectedBuckets"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = var.iam_denied_resources

    condition {
      test     = "StringEqualsIfExists"
      variable = "s3:ResourceAccount"
      values   = [var.account_id]
    }
  }
}
