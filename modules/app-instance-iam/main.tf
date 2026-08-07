resource "aws_iam_role" "app_instance" {
  name               = local.app_instance_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_app_instance.json
  tags               = merge(local.tags, { "Name" = local.app_instance_role_name })
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${var.prefix}-profile"
  role = aws_iam_role.app_instance.name
  tags = merge(local.tags, { "Name" = "${var.prefix}-profile" })
}

# --- policies ---

resource "aws_iam_policy" "logs_app_instance" {
  name   = "${var.prefix}-cloudwatch-logs"
  policy = data.aws_iam_policy_document.logs_app_instance.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-cloudwatch-logs" })
}

resource "aws_iam_policy" "ssm_user" {
  name   = "${local.prefix}-ssm-user"
  policy = data.aws_iam_policy_document.ssm_user.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-ssm-user" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "app_instance_ssm" {
  # Secure Session Manager (SSM) allows for connecting to instances using IAM, without the need for
  # SSH keys or bastion hosts.  This enables core SSM functionality on Michelangelo instances:
  #
  # https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonSSMManagedInstanceCore.html
  #
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "logs_app_instance" {
  role       = aws_iam_role.app_instance.name
  policy_arn = aws_iam_policy.logs_app_instance.arn
}

resource "aws_iam_role_policy_attachment" "ssm_user" {
  role       = var.workbench_user_role_name
  policy_arn = aws_iam_policy.ssm_user.arn
}
