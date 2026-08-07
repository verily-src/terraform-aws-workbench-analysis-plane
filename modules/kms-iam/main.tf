# --- kms policies ---

resource "aws_iam_policy" "kms_user" {
  name   = "${local.prefix}-user"
  policy = data.aws_iam_policy_document.kms_user.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user" })
}

resource "aws_iam_policy" "kms_user_ec2_instance_create_grant" {
  name   = "${local.prefix}-user-create-grant"
  policy = data.aws_iam_policy_document.kms_user_ec2_instance_create_grant.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user-create-grant" })
}

resource "aws_iam_policy" "kms_manager" {
  name   = "${local.prefix}-manager"
  policy = data.aws_iam_policy_document.kms_manager.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manager" })
}

# --- policy attachments ---

resource "aws_iam_role_policy_attachment" "kms_manager" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.kms_manager.arn
}

resource "aws_iam_role_policy_attachment" "kms_user" {
  for_each   = toset(var.kms_user_role_names)
  role       = each.key
  policy_arn = aws_iam_policy.kms_user.arn
}

resource "aws_iam_role_policy_attachment" "kms_grant" {
  for_each   = toset(var.kms_user_role_names)
  role       = each.key
  policy_arn = aws_iam_policy.kms_user_ec2_instance_create_grant.arn
}
