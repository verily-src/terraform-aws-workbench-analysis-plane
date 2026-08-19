
resource "aws_iam_role" "discovery" {
  name               = local.prefix
  assume_role_policy = data.aws_iam_policy_document.assume_discovery.json
}

# --- policies ---

resource "aws_iam_policy" "discovery" {
  name   = "${local.prefix}-bucket"
  policy = data.aws_iam_policy_document.discovery.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-bucket" })
}

resource "aws_iam_policy" "discovery_kms" {
  name   = "${local.prefix}-kms"
  policy = data.aws_iam_policy_document.discovery_kms.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-kms" })
}

resource "aws_iam_policy" "discovery_iam" {
  name   = "${local.prefix}-iam"
  policy = data.aws_iam_policy_document.discovery_iam.json
  tags   = merge(local.tags, { "Name" = "${local.prefix}-iam" })
}

# --- attachments ---

resource "aws_iam_role_policy_attachment" "discovery" {
  role       = aws_iam_role.discovery.name
  policy_arn = aws_iam_policy.discovery.arn
}

resource "aws_iam_role_policy_attachment" "discovery_kms" {
  role       = aws_iam_role.discovery.name
  policy_arn = aws_iam_policy.discovery_kms.arn
}

resource "aws_iam_role_policy_attachment" "discovery_iam" {
  role       = aws_iam_role.discovery.name
  policy_arn = aws_iam_policy.discovery_iam.arn
}

