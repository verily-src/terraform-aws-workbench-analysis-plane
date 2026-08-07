# --- assume role policy for workspace user role ---

data "aws_iam_policy_document" "assume_workbench_user" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.workspace_manager.arn]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# --- assume role policy for workspace manager role ---

data "aws_iam_policy_document" "assume_workspace_manager" {
  statement {

    # This specifies a federated identity using Google's OIDC Provider, which is
    # trusted by AWS.
    principals {
      type        = "Federated"
      identifiers = ["accounts.google.com"]
    }

    # GCP caller will use the Secure Token Service (STS) AssumeRoleWithWebIdentity
    # API to assume this role, passing a GCP-generated JWT for a service account
    # and getting temporary AWS creds in return.
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    # This condition allows a caller of AssumeRoleWithWebIdentity to obtain
    # credentials to assume a role with this policy document attached if the
    # passed JWT audience (aud) claim exists in the list contained in variable
    # gcp_service_account_ids.
    # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#ck_aud

    condition {
      test     = "StringEquals"
      variable = "accounts.google.com:oaud"
      values   = [var.workspace_manager_gcp_service_account.aud]
    }
    condition {
      test     = "StringEquals"
      variable = "accounts.google.com:sub"
      values   = [var.workspace_manager_gcp_service_account.sub]
    }
  }

  # regression testing role assumption
  dynamic "statement" {
    for_each = toset(var.regression_testing_assume_role_arns)
    content {
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = ["sts:AssumeRole"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_manager" {
  statement {
    sid    = "AllowListAndGetMetrics"
    effect = "Allow"

    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics"
    ]
    resources = ["*"]
  }
}
