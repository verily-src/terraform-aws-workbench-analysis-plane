resource "aws_iam_role" "notebook" {
  name               = local.notebook_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_notebook.json
  tags               = merge(local.tags, { "Name" = local.notebook_role_name })
}

# --- policies ---

resource "aws_iam_policy" "logs_notebook" {
  name   = "${var.prefix}-notebook-logs"
  policy = data.aws_iam_policy_document.logs_notebook.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-notebook-logs" })
}

resource "aws_iam_policy" "sagemaker_notebook" {
  name   = "${var.prefix}-notebook-sagemaker"
  policy = data.aws_iam_policy_document.sagemaker_notebook.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-notebook-sagemaker" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "logs_notebook" {
  role       = local.notebook_role_name
  policy_arn = aws_iam_policy.logs_notebook.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker_notebook" {
  role       = local.notebook_role_name
  policy_arn = aws_iam_policy.sagemaker_notebook.arn
}
