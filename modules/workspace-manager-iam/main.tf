resource "aws_iam_role" "workspace_manager" {
  name               = local.workspace_manager_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_workspace_manager.json

  tags = merge(
    local.tags,
    { "Name" = local.workspace_manager_role_name }
  )
}

resource "aws_iam_role" "workbench_user" {
  name               = local.workbench_user_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_workbench_user.json

  tags = merge(
    local.tags,
    { "Name" = local.workbench_user_role_name }
  )
}

# --- policies ---

resource "aws_iam_policy" "cloudwatch_manager" {
  name   = "${local.prefix}-cloudwatch-manager"
  policy = data.aws_iam_policy_document.cloudwatch_manager.json

  tags = merge(
    local.tags,
    { "Name" = "${local.prefix}-cloudwatch-manager" }
  )
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "cloudwatch_manager" {
  role       = aws_iam_role.workspace_manager.name
  policy_arn = aws_iam_policy.cloudwatch_manager.arn
}

# --- default AWS role attachments ---

# allow workspace manager full access to EC2
resource "aws_iam_role_policy_attachment" "ec2_workspace_manager_allow_full_ec2" {
  role       = aws_iam_role.workspace_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# allow workspace manager full access to Network Reachability Analyzer
resource "aws_iam_role_policy_attachment" "ec2_workspace_manager_allow_full_reachability" {
  role       = aws_iam_role.workspace_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCReachabilityAnalyzerFullAccessPolicy"
}

# allow workspace manager full access to Sagemaker
resource "aws_iam_role_policy_attachment" "sagemaker_workspace_manager_allow" {
  role       = aws_iam_role.workspace_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

