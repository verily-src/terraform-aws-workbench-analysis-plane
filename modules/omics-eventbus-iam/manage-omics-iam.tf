resource "aws_iam_policy" "manage_omics_iam" {
  name   = "${local.prefix}-manage_iam"
  policy = data.aws_iam_policy_document.manage_omics_iam.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manage_iam" })
}

resource "aws_iam_role_policy_attachment" "workflow_manager_iam" {
  role       = var.workflow_manager_role_name
  policy_arn = aws_iam_policy.manage_omics_iam.arn
}

# --- policy documents ---

data "aws_iam_policy_document" "manage_omics_iam" {
  statement {
    sid = "${var.sid_prefix}CreateExecutionRole"

    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy"
    ]
    resources = [var.execution_role_arn_pattern]

    condition {
      test     = "ArnEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.execution_permission_boundary.arn]
    }
  }

  statement {
    sid = "${var.sid_prefix}ManageExecutionRoles"

    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:TagRole"
    ]
    resources = [var.execution_role_arn_pattern]
  }

  statement {
    sid = "${var.sid_prefix}DenyPermissionBoundaryChanges"

    effect = "Deny"
    actions = [
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:DeleteRolePermissionsBoundary"
    ]
    resources = ["*"]
  }
}
