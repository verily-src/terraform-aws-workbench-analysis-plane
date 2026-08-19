# --- policies ---

resource "aws_iam_policy" "aurora_user_actions" {
  name   = "${local.prefix}-user-actions"
  policy = data.aws_iam_policy_document.aurora_user_actions.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user-actions" })
}

resource "aws_iam_policy" "aurora_manager" {
  name   = "${local.prefix}-manager"
  policy = data.aws_iam_policy_document.aurora_manager_admin.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manager" })
}

# --- attachements ---

resource "aws_iam_role_policy_attachment" "aurora_manager" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.aurora_manager.arn
}

resource "aws_iam_role_policy_attachment" "aurora_user_actions" {
  for_each   = toset(var.aurora_user_role_names)
  role       = each.key
  policy_arn = aws_iam_policy.aurora_user_actions.arn
}
