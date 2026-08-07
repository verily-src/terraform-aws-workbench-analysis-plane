# The OmicsUserDelegate role can only be assumed by the WorkflowManager role. The WorkflowManager
# role does not have any Omics permissions directly. It can only manage Omics resources by assuming
# the OmicsUserDelegate role. When assuming this role, the session can be tagged in 2 ways:
#   1. Using a specific WorkflowId tag. This session will be allowed to list, create and delete
#      omics resources tagged with the same WorkflowId as the session. It can also pass execution
#      roles with the same WorkflowId tag to the Omics runs it starts. 
#   2. Using an "admin" SessionType tag. Admin sessions are meant to perform janitor tasks, like
#      listing and cleaning up dangling workflows, but they are not meant to run omics workflows.
# For more details, see the policy_omics.tf and policy_iam.tf files.

resource "aws_iam_role" "omics_user_delegate" {
  name               = "${var.prefix}-user-delegate"
  assume_role_policy = data.aws_iam_policy_document.assume_omics_user_delegate.json
  tags               = merge(local.tags, { "Name" = "${var.prefix}-user-delegate" })
}

# iam policy allowing the OmicsUserDelegate role to pass an execution role to Omics Runs.
resource "aws_iam_policy" "omics_delegate_pass_role" {
  name   = "${var.prefix}-delegate-pass-role"
  policy = data.aws_iam_policy_document.omics_delegate_pass_role.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-delegate-pass-role" })
}

resource "aws_iam_role_policy_attachment" "omics_delegate_pass_role" {
  role       = aws_iam_role.omics_user_delegate.name
  policy_arn = aws_iam_policy.omics_delegate_pass_role.arn
}

resource "aws_iam_role_policy_attachment" "omics_delegate_workflows" {
  role       = aws_iam_role.omics_user_delegate.name
  policy_arn = aws_iam_policy.omics_delegate_manage_workflows.arn
}

# --- policy documents ---

data "aws_iam_policy_document" "assume_omics_user_delegate" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.workflow_manager_role_arn]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

data "aws_iam_policy_document" "omics_delegate_pass_role" {
  statement {
    sid       = "PassOmicsExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [var.execution_role_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["omics.amazonaws.com"]
    }
    condition {
      test     = "Null"
      variable = "iam:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workspace_id}}"]
    }
  }
}
