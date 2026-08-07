# Accessing resources in OTHER AWS accounts via resource-based policies requires
# that identity-based policies exist in THIS AWS account that allow this access:
#
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic-cross-account.html
#
# This IAM policy uses ABAC such that the Workspace Manager can assume an
# "External Access" IAM role (to which this policy is attached) on behalf of a
# user with a set of tags that specify the user's permissions on an externally
# shared S3 bucket to satisfy the "trusted account" requirement for cross-
# account access as described in the document linked above.
#
# Note that the "trusting account" resource-based permissions are not under the
# control of this Terraform module and must be managed by the administrator of
# that account.
data "aws_iam_policy_document" "s3_external_access" {

  # Explicitly deny access to any buckets within this account so that an
  # "external bucket" resource cannot be abused to gain access to account-local
  # S3 buckets.
  statement {
    sid    = "${var.sid_prefix}ExternalAccessDenyLocal"
    effect = "Deny"

    actions = [
      "s3:*",
    ]
    resources = ["arn:aws:s3:::*"]

    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values   = [var.account_id]
    }
  }

  # Grant access to action s3:ListBucket on an S3 bucket in another AWS account
  # to a reader or writer of a workspace.
  statement {
    sid = "${var.sid_prefix}ExternalAccessBucket"

    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.external_bucket_id}}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.external_bucket_prefix}}*"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.external_bucket_account}}"]
    }
  }

  # Grant access to read and describe objects in an S3 bucket in another AWS
  # account to a reader or writer of a workspace.
  statement {
    sid = "${var.sid_prefix}ExternalAccessObjectRead"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.external_bucket_id}}/$${aws:PrincipalTag/${var.principal_tags.external_bucket_prefix}}*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.external_bucket_account}}"]
    }
  }

  # Grant access to put and delete objects in an S3 bucket in another AWS
  # account to a writer of a workspace.
  statement {
    sid = "${var.sid_prefix}ExternalAccessObjectWrite"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::$${aws:PrincipalTag/${var.principal_tags.external_bucket_id}}/$${aws:PrincipalTag/${var.principal_tags.external_bucket_prefix}}*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["writer"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.external_bucket_account}}"]
    }
  }
}
