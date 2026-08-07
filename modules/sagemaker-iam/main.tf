# --- policies ---

resource "aws_iam_policy" "sagemaker_user" {
  name   = "${local.prefix}-user"
  policy = data.aws_iam_policy_document.sagemaker_user_sagemaker.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user" })
}

resource "aws_iam_policy" "sagemaker_manager_deny" {
  name   = "${local.prefix}-manager-deny"
  policy = data.aws_iam_policy_document.sagemaker_manager_deny.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manager-deny" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "sagemaker_manager_deny" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.sagemaker_manager_deny.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker_user" {
  role       = var.workbench_user_role_name
  policy_arn = aws_iam_policy.sagemaker_user.arn
}
