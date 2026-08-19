# The OmicsUserDelegate role can only be assumed by the WorkflowManager role. The WorkflowManager
# role does not have any Omics permissions directly. It can only manage Omics resources by assuming
# the OmicsUserDelegate role. When assuming this role, the session can be tagged in 2 ways:
#   1. Using a specific WorkflowId tag. This session will be allowed to list, create and delete
#      omics resources tagged with the same WorkflowId as the session. It can also pass execution
#      roles with the same WorkflowId tag to the Omics runs it starts. 
#   2. Using an "admin" SessionType tag. Admin sessions are meant to perform janitor tasks, like
#      listing and cleaning up dangling workflows, but they are not meant to run omics workflows.
# For more details, see the policy_omics.tf and policy_iam.tf files.

resource "aws_iam_policy" "omics_delegate_manage_workflows" {
  name   = "${var.prefix}-delegate-manage-workflows"
  policy = data.aws_iam_policy_document.omics_delegate_manage_workflows.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-delegate-manage-workflows" })
}

data "aws_iam_policy_document" "omics_delegate_manage_workflows" {
  # A session tagged with a specific WorkflowId can trigger requests to create and start runs, as
  # long as those resources are tagged with the same WorkflowId tag.
  statement {
    sid    = "${var.sid_prefix}CreateTaggedOmicsResources"
    effect = "Allow"

    actions = [
      "omics:CreateWorkflow",
      "omics:StartRun",
      "omics:TagResource",
      "omics:CreateRunCache",
      "omics:StartRunBatch",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/${var.resource_tags.workspace_id}"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/${var.resource_tags.workspace_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workspace_id}}"]
    }
  }

  # A session tagged with a specific WorkflowId can cancel and delete omics resources, as
  # long as those resources are tagged with the same WorkflowId tag.
  statement {
    sid    = "${var.sid_prefix}DeleteTaggedOmicsResources"
    effect = "Allow"

    actions = [
      "omics:CancelRun",
      "omics:DeleteRun",
      "omics:DeleteWorkflow",
      "omics:DeleteRunCache",
      "omics:CancelRunBatch",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["$${aws:PrincipalTag/${var.principal_tags.workspace_id}}"]
    }
  }

  # An admin session can delete workflows, as long as the workflow has a WorkflowId tag, regardless
  # of the value.
  statement {
    sid    = "${var.sid_prefix}AdminDeleteTaggedWorkflow"
    effect = "Allow"

    actions = [
      "omics:DeleteWorkflow",
      "omics:DeleteRunCache",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/${var.resource_tags.workspace_id}"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/${var.principal_tags.session_type}"
      values   = ["admin"]
    }
  }

  # All sessions can list and get workflows, runs and tasks, regardless of their tags.
  statement {
    sid    = "${var.sid_prefix}ReadOmicsResources"
    effect = "Allow"

    actions = [
      "omics:GetRun",
      "omics:GetRunTask",
      "omics:GetWorkflow",
      "omics:ListWorkflows",
      "omics:GetRunCache",
      "omics:ListRunCaches",
      "omics:GetBatch",
      "omics:ListRunsInBatch",
    ]
    resources = ["*"]
  }
}
