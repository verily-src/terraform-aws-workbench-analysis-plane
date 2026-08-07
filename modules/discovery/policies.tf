data "aws_iam_policy_document" "assume_discovery" {
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
      values   = [var.gcp_service_accounts.aud]
    }

    condition {
      test     = "StringEquals"
      variable = "accounts.google.com:sub"
      values   = var.gcp_service_accounts.sub
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

# --- discovery policy document ---

data "aws_iam_policy_document" "discovery" {
  statement {
    sid = "${var.sid_prefix}WorkbenchDiscoveryBucketList"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.discovery.id}"]
  }

  statement {
    sid = "${var.sid_prefix}WorkbenchDiscoveryBucketRead"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.discovery.id}/*",
    ]
  }
}

# --- kms policy document ---

data "aws_iam_policy_document" "discovery_kms" {
  statement {
    sid = "${var.sid_prefix}WorkbenchDiscoveryBucketDecrypt"

    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.discovery_bucket.arn]
  }
}

# --- iam policy document ---

data "aws_iam_policy_document" "discovery_iam" {
  statement {
    sid       = "AllowDiscoveryRoleGetAppInstanceRole"
    effect    = "Allow"
    actions   = ["iam:GetRole"]
    resources = var.app_instance_role_arns
  }
}
