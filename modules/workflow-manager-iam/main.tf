resource "aws_iam_role" "workflow_manager" {
  name               = local.workflow_manager_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_workflow_manager.json
  tags               = merge(local.tags, { "Name" = local.workflow_manager_role_name })
}

