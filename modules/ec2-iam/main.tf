# --- policies ---

resource "aws_iam_policy" "ec2_server_read" {
  name   = "${local.prefix}-server-read"
  policy = data.aws_iam_policy_document.ec2_server_read.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-server-read" })
}

resource "aws_iam_policy" "ec2_app_instance_self_actions" {
  name   = "${var.prefix}-self-actions"
  policy = data.aws_iam_policy_document.ec2_app_instance_self_actions.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-self-actions" })
}

resource "aws_iam_policy" "ec2_user_actions" {
  name   = "${local.prefix}-user-actions"
  policy = data.aws_iam_policy_document.ec2_user_actions.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user-actions" })
}

resource "aws_iam_policy" "ec2_manager_pass_role" {
  name   = "${local.prefix}-manager-pass-role"
  policy = data.aws_iam_policy_document.ec2_manager_pass_role.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-manager-pass-role" })
}

resource "aws_iam_policy" "ec2_user_pass_role" {
  name   = "${local.prefix}-user-pass-role"
  policy = data.aws_iam_policy_document.ec2_user_pass_role.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-user-pass-role" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "ec2_server_read" {
  role       = var.axon_server_role_name
  policy_arn = aws_iam_policy.ec2_server_read.arn
}

resource "aws_iam_role_policy_attachment" "ec2_app_instance_self_actions" {
  role       = var.app_instance_role_name
  policy_arn = aws_iam_policy.ec2_app_instance_self_actions.arn
}

resource "aws_iam_role_policy_attachment" "ec2_manager_pass_role" {
  role       = var.workspace_manager_role_name
  policy_arn = aws_iam_policy.ec2_manager_pass_role.arn
}

resource "aws_iam_role_policy_attachment" "ec2_user_pass_role" {
  role       = var.workbench_user_role_name
  policy_arn = aws_iam_policy.ec2_user_pass_role.arn
}

resource "aws_iam_role_policy_attachment" "ec2_user_actions" {
  role       = var.workbench_user_role_name
  policy_arn = aws_iam_policy.ec2_user_actions.arn
}
