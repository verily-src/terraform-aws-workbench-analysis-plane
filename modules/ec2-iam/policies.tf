
# Allow WSM to pass Application Framework Instance IAM Role to EC2 Service
data "aws_iam_policy_document" "ec2_manager_pass_role" {
  statement {
    sid       = "${var.sid_prefix}AllowPassAppInstanceRole"
    actions   = ["iam:PassRole"]
    resources = [var.app_instance_role_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

# Allow user to pass Application Framework Instance IAM Role to EC2 Service.  This is required to
# enable users to start instances, as starting an instance requires passing the role to the EC2
# service.
data "aws_iam_policy_document" "ec2_user_pass_role" {
  statement {
    sid       = "AllowPassAppInstanceRole"
    actions   = ["iam:PassRole"]
    resources = [var.app_instance_role_arn]

    # This ensures that the role is only ever pass to the EC2 service
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

# Set policy for the user role on EC2 resources
data "aws_iam_policy_document" "ec2_user_actions" {
  statement {
    sid = "AllowActionsOwnedInstance"

    actions = [
      # ec2:GetConsole* actions
      "ec2:GetConsoleOutput",
      "ec2:GetConsoleScreenshot",

      # Start/stop actions.  Note that ec2:StartInstances also requires iam:PassRole on the
      # AppInstance IAM role and kms:CreateGrant on the KMS key used to encrypt attached volumes.
      "ec2:RebootInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]

    # This policy relies on principal tags to limit these actions to the user's owned instances
    resources = ["arn:aws:ec2:*:*:instance/*"]

    # User ID principal tag must match resource tag, as these are private resources
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.user_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.user_id}}"]
    }

    # Resource ID principal tag must match resource tag
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.resource_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.resource_id}}"]
    }

    # Workspace ID principal tag must match resource tag
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workspace_id}}"]
    }
  }

  # Allow the user to create/delete tags to/from EC2 resources (instances, network interfaces,
  # volumes) that they own, but ONLY if the tag key start with "vwbusr:" (to disallow
  # putting/deleting any tags used in IAM policies)
  statement {
    sid = "AllowPutDeleteUserTagsOwned"

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["arn:aws:ec2:*:*:instance/*"]

    # User ID principal tag must match resource tag, as these are private resources
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.user_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.user_id}}"]
    }

    # Resource ID principal tag must match resource tag
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.resource_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.resource_id}}"]
    }

    # Workspace ID principal tag must match resource tag
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workspace_id}}"]
    }

    # IMPORTANT! This is required to make sure that a "ec2:DeleteTags" is only allowed if at least
    # one tag key is passed.  When this action is invoked with no tag keys, all tags on the instance
    # are deleted.  If this condition is ommitted, deleting all tags is implcitly permitted by the
    # actions in this policy statement.
    #
    # Ref: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_tags.html#access_tags_control-tag-keys
    #
    condition {
      test     = "Null"
      variable = "aws:TagKeys"
      values   = ["false"]
    }

    # The key of the tag to put/delete must begin with prefix "vwbusr:"
    condition {
      test     = "ForAllValues:StringLike"
      variable = "aws:TagKeys"
      values   = ["vwbusr:*"]
    }
  }
}

# Actions that the instance's running IAM role can perform
data "aws_iam_policy_document" "ec2_app_instance_self_actions" {
  # Allow the instance to read its own tags (as well as all others in LZ).  Unfortunately, no
  # ec2:Describe* actions allow any more granular permission than "*", nor do they support
  # resource tags.
  #
  # In the future, when VWB can support authentication to the control plane via instance doc and/or
  # IAM role, we can remove this.  But it is required for now to allow an instance to discover its
  # own VWB tenant, workspace, and resource ID's.
  #
  statement {
    sid       = "AllowDescribeTagsSelf"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }

  # Allow the instance to add/delete tags to/from itself, but ONLY if the tag key start with
  # "vwbapp:" (to disallow putting/deleting any tags used in IAM policies)
  statement {
    sid = "AllowWCreateDeleteTagsSelf"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["arn:aws:ec2:*:*:instance/*"]

    # See doc on equivalent condition in statement SID 'AllowDescribeTagsSelf' above
    condition {
      test     = "StringEquals"
      variable = "aws:userid"
      values   = ["${var.app_instance_role_unique_id}:$${ec2:InstanceID}"]
    }

    # IMPORTANT! This is required to make sure that a "ec2:DeleteTags" is only allowed if at least
    # one tag key is passed.  When this action is invoked with no tag keys, all tags on the instance
    # are deleted.  If this condition is ommitted, deleting all tags is implcitly permitted by the
    # actions in this policy statement.
    #
    # Ref: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_tags.html#access_tags_control-tag-keys
    #
    condition {
      test     = "Null"
      variable = "aws:TagKeys"
      values   = ["false"]
    }

    # The key of the tag to put/delete must begin with prefix "vwbapp:"
    condition {
      test     = "ForAllValues:StringLike"
      variable = "aws:TagKeys"
      values   = ["vwbapp:*"]
    }
  }
}

# Allow read-only access to EC2 instance types
data "aws_iam_policy_document" "ec2_server_read" {
  statement {
    sid = "AllowDescribeInstanceTypes"

    actions = [
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
    ]
    resources = ["*"]
  }
}
