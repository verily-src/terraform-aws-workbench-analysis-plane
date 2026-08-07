data "aws_iam_policy_document" "allow_only" {
  statement {
    sid    = "DenyObjectNotAssumedRoles"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:PutObject",
      "s3:RestoreObject",
    ]
    resources = [
      aws_s3_bucket.default.arn,
      "${aws_s3_bucket.default.arn}/*",
    ]

    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = local.allowed_userids
    }

    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values   = var.allowed_bucket_object_role_principal_arns
    }

    dynamic "condition" {
      for_each = var.datasync_iam_role_arn != null ? [var.datasync_iam_role_arn] : []
      content {
        test     = "StringNotLike"
        variable = "aws:PrincipalArn"
        values   = [condition.value]
      }
    }
  }
}
