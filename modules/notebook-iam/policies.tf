# --- notebook role assume policy ---
data "aws_iam_policy_document" "assume_notebook" {
  statement {

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

# --- logs notebook policy ---

data "aws_iam_policy_document" "logs_notebook" {
  statement {
    sid       = "${var.sid_prefix}AllowCreateLogGoups"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "${var.sid_prefix}AllowWriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/sagemaker/NotebookInstances:*"]
  }
}

# --- sagemaker notebook policy ---

data "aws_iam_policy_document" "sagemaker_notebook" {
  statement {
    sid    = "${var.sid_prefix}AllowListTags"
    effect = "Allow"
    actions = [
      "sagemaker:ListTags",
    ]
    resources = ["arn:aws:sagemaker:*:*:notebook-instance/*"]
  }
}
