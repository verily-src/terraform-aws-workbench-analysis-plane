# Accessing resources in OTHER AWS accounts via resource-based policies requires
# that identity-based policies exist in THIS AWS account that allow this access:
#
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic-cross-account.html
#
# This IAM policy uses ABAC such that the Workspace Manager can assume an
# "External Access" IAM role (to which this policy is attached) on behalf of a
# user with a set of tags that specify the user's permissions on an externally
# shared ECR repository to satisfy the "trusted account" requirement for cross-
# account access as described in the document linked above.
#
# The policy uses a combination of:
#
# 1. Resource ARN patterns with dynamic repository names from principal tags 
# 2. The aws:ResourceAccount condition to restrict access to repositories in
#    a specific account
# 3. The aws:RequestedRegion condition to restrict access to respositories in
#    a specific region
# 4. Role-based conditions to enforce RBAC (reader vs writer permissions)
#
# 1, 2 & 3 are necessary because the resource ARN may not contain a variable
# for the account ID or region field, while the resource field of the ARN may.
# Also, multiple repositories may exist in the same account with the same name
# across different regions, so the region must also be specified to pinpoint
# the correct repository.
#
# Note that the "trusting account" resource-based permissions are not under the
# control of this Terraform module and must be managed by the administrator of
# that account.

data "aws_iam_policy_document" "ecr_external_access" {

  # Explicitly deny access to any repositories within this account so that an
  # "external repository" resource cannot be abused to gain access to account-local
  # ECR repositories.
  statement {
    sid    = "${var.sid_prefix}ExternalAccessDenyLocal"
    effect = "Deny"

    actions = [
      "ecr:*",
    ]
    resources = ["arn:aws:ecr:*:${var.account_id}:repository/*"]
  }

  # Grant access to describe and list images in a specific ECR repository in another AWS account
  # to a reader or writer of a workspace when external_repository_name is set.
  statement {
    sid = "${var.sid_prefix}ExternalAccessRepository"

    actions = local.ecr_read_actions
    resources = [
      "arn:aws:ecr:*:*:repository/$${aws:PrincipalTag/${var.principal_tags.external_repository_name}}",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }

    # Extract the account ID from AWS Principal tags
    condition {
      test     = local.common_account_condition.test
      variable = local.common_account_condition.variable
      values   = local.common_account_condition.values
    }

    # Extract the repository region from AWS Principal tags
    condition {
      test     = local.common_region_condition.test
      variable = local.common_region_condition.variable
      values   = local.common_region_condition.values
    }
  }

  # Grant access to describe and list images in ALL ECR repositories in another AWS account
  # when external_repository_name tag is NOT present. This provides broader registry access.
  statement {
    sid = "${var.sid_prefix}ExternalAccessAllRepositories"

    actions = local.ecr_read_actions
    resources = [
      "arn:aws:ecr:*:*:repository/*",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }

    # Only apply when external_repository_name tag is NOT present
    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${var.principal_tags.external_repository_name}"
      values   = ["true"]
    }

    # Extract the account ID from AWS Principal tags
    condition {
      test     = local.common_account_condition.test
      variable = local.common_account_condition.variable
      values   = local.common_account_condition.values
    }

    # Extract the repository region from AWS Principal tags
    condition {
      test     = local.common_region_condition.test
      variable = local.common_region_condition.variable
      values   = local.common_region_condition.values
    }
  }

  # Grant access to get authentication token for ECR operations.
  # Note: ecr:GetAuthorizationToken can only be granted at the '*' resource level per AWS design.
  # This statement alone doesn't grant image pull permissions - it only allows authentication.
  # The actual ability to pull images is controlled by repository-specific permissions in the 
  # WorkbenchExternalAccessRepository statement above.
  statement {
    sid = "${var.sid_prefix}ExternalAccessImagePull"

    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["reader", "writer"]
    }
  }

  # Grant access to push and delete images in a specific ECR repository in another AWS
  # account to a writer of a workspace when external_repository_name is set.
  statement {
    sid = "${var.sid_prefix}ExternalAccessImagePush"

    actions = local.ecr_write_actions
    resources = [
      "arn:aws:ecr:*:*:repository/$${aws:PrincipalTag/${var.principal_tags.external_repository_name}}",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["writer"]
    }

    # Extract the account ID from AWS Principal tags
    condition {
      test     = local.common_account_condition.test
      variable = local.common_account_condition.variable
      values   = local.common_account_condition.values
    }

    # Extract the repository region from AWS Principal tags
    condition {
      test     = local.common_region_condition.test
      variable = local.common_region_condition.variable
      values   = local.common_region_condition.values
    }
  }

  # Grant access to push and delete images in ALL ECR repositories in another AWS account
  # when external_repository_name tag is NOT present. This provides broader registry write access.
  statement {
    sid = "${var.sid_prefix}ExternalAccessAllRepositoriesImagePush"

    actions = local.ecr_write_actions
    resources = [
      "arn:aws:ecr:*:*:repository/*",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.ws_role}"
      values   = ["writer"]
    }

    # Only apply when external_repository_name tag is NOT present
    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${var.principal_tags.external_repository_name}"
      values   = ["true"]
    }

    # Extract the account ID from AWS Principal tags
    condition {
      test     = local.common_account_condition.test
      variable = local.common_account_condition.variable
      values   = local.common_account_condition.values
    }

    # Extract the repository region from AWS Principal tags
    condition {
      test     = local.common_region_condition.test
      variable = local.common_region_condition.variable
      values   = local.common_region_condition.values
    }
  }
}
