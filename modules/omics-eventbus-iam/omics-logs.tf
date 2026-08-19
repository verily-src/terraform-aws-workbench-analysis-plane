# --- log reader workflow manager policy ---

resource "aws_iam_policy" "logs_reader" {
  name   = "${local.prefix}-logs-reader"
  policy = data.aws_iam_policy_document.logs_reader.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-logs-reader" })
}

resource "aws_iam_role_policy_attachment" "workflow_manager_logs" {
  role       = var.workflow_manager_role_name
  policy_arn = aws_iam_policy.logs_reader.arn
}

# --- policy documents ---

data "aws_iam_policy_document" "logs_reader" {
  statement {
    sid       = "${var.sid_prefix}GetWorkflowLogs"
    effect    = "Allow"
    actions   = ["logs:GetLogEvents"]
    resources = [var.omics_log_group]
  }
}
