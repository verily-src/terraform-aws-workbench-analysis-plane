# --- policies ---

resource "aws_iam_policy" "s3_user" {
  name   = "${local.prefix}-users"
  policy = data.aws_iam_policy_document.s3_user.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-users" })
}

resource "aws_iam_policy" "s3_manager" {
  name   = "${local.prefix}-manager"
  policy = data.aws_iam_policy_document.s3_manager.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manager" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "s3_manager" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.s3_manager.arn
}

resource "aws_iam_role_policy_attachment" "s3_user" {
  for_each   = toset(var.s3_user_role_names)
  role       = each.value
  policy_arn = aws_iam_policy.s3_user.arn
}
