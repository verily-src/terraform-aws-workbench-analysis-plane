data "aws_iam_policy_document" "efs_policy" {
  for_each = aws_efs_file_system.default

  statement {
    sid    = "${var.sid_prefix}DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["*"]
    resources = [each.value.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}DenyAnonymousAccess"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = [each.value.arn]

    condition {
      test     = "Null"
      variable = "aws:PrincipalArn"
      values   = ["true"]
    }
  }
}

