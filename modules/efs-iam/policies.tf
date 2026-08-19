# --- efs user policy ---

data "aws_iam_policy_document" "efs_user" {
  statement {
    sid    = "${var.sid_prefix}EFSUserDescribeMountTargets"
    effect = "Allow"

    actions = [
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = ["arn:aws:elasticfilesystem:*:${var.account_id}:file-system/*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}EFSUserMount"
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientMount"
    ]
    resources = ["arn:aws:elasticfilesystem:*:${var.account_id}:file-system/*"]

    condition {
      test     = "ArnEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = ["arn:aws:elasticfilesystem:*:${var.account_id}:access-point/$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}EFSUserWrite"
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientWrite"
    ]
    resources = ["arn:aws:elasticfilesystem:*:${var.account_id}:file-system/*"]

    condition {
      test     = "ArnEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = ["arn:aws:elasticfilesystem:*:${var.account_id}:access-point/$${aws:PrincipalTag/${var.principal_tags.workbench_bucket_id}}"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["writer"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}EFSUserDenyDirectMount"
    effect = "Deny"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = ["arn:aws:elasticfilesystem:*:${var.account_id}:file-system/*"]

    condition {
      test     = "Null"
      variable = "elasticfilesystem:AccessPointArn"
      values   = ["true"]
    }
  }

  statement {
    sid    = "${var.sid_prefix}EFSUserDenyRoot"
    effect = "Deny"

    actions = [
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = ["*"]
  }
}

# --- efs manager policy ---

data "aws_iam_policy_document" "efs_workspace_manager" {
  statement {
    sid    = "${var.sid_prefix}EFSAccessPointManagement"
    effect = "Allow"

    actions = [
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:TagResource",
      "elasticfilesystem:UntagResource",
      "elasticfilesystem:ListTagsForResource",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${var.resource_tags.efs}"
      values   = ["true"]
    }
  }

  # Allow WSM to describe file systems (read-only, for discovery)
  statement {
    sid    = "${var.sid_prefix}EFSDescribeFileSystems"
    effect = "Allow"

    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeMountTargetSecurityGroups",
    ]
    resources = ["*"]
  }
}
