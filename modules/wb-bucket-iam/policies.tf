# --- s3 user ---

data "aws_iam_policy_document" "s3_user" {
  statement {
    sid = "${var.sid_prefix}UserBucket"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.bucket_id}}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}/*"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }
  }

  statement {
    sid = "${var.sid_prefix}UserObjectRead"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAttributes"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.bucket_id}}/$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}/*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }
  }

  statement {
    sid = "${var.sid_prefix}UserObjectWrite"

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.bucket_id}}/$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}/*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["writer"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}UserObjectWriteDeny"
    effect = "Deny"

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.bucket_id}}/$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}"]
  }
}

# --- s3 workspace manager ---

data "aws_iam_policy_document" "s3_manager" {
  statement {
    sid = "${var.sid_prefix}WorkspaceManagerBucket"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = ["arn:aws:s3:::${var.bucket_name_prefix}*"]
  }

  statement {
    sid = "${var.sid_prefix}WorkspaceManagerObject"

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name_prefix}*",
      "arn:aws:s3:::${var.bucket_name_prefix}*/*",
    ]
  }

  statement {
    sid    = "${var.sid_prefix}WorkspaceManagerDeny"
    effect = "Deny"

    actions = [
      "s3:*",
    ]
    resources = var.iam_denied_resources
  }
}
