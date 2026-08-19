
# --- efs user policies ---

resource "aws_iam_policy" "efs_user" {
  name   = "${local.prefix}-user"
  policy = data.aws_iam_policy_document.efs_user.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-user" })
}

resource "aws_iam_policy" "efs_workspace_manager" {
  name   = "${local.prefix}-workspace-manager"
  policy = data.aws_iam_policy_document.efs_workspace_manager.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-manager" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "efs_user" {
  for_each   = toset(var.efs_user_role_names)
  role       = each.key
  policy_arn = aws_iam_policy.efs_user.arn
}

resource "aws_iam_role_policy_attachment" "efs_manager" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.efs_workspace_manager.arn
}
