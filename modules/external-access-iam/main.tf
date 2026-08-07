resource "aws_iam_role" "external_access" {
  name               = local.external_access_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_external_access.json

  tags = merge(
    local.tags,
    { "Name" = local.external_access_role_name }
  )
}

# --- policies ---

resource "aws_iam_policy" "ecr_external_access" {
  name   = "${local.prefix}-ecr"
  policy = data.aws_iam_policy_document.ecr_external_access.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-ecr" })
}

resource "aws_iam_policy" "s3_external_access" {
  name   = "${local.prefix}-s3"
  policy = data.aws_iam_policy_document.s3_external_access.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-s3" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "ecr_external_access" {
  role       = aws_iam_role.external_access.name
  policy_arn = aws_iam_policy.ecr_external_access.arn
}

resource "aws_iam_role_policy_attachment" "s3_external_access" {
  role       = aws_iam_role.external_access.name
  policy_arn = aws_iam_policy.s3_external_access.arn
}

# --- assume role policy ---

data "aws_iam_policy_document" "assume_external_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.workspace_manager_role_arn]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}
