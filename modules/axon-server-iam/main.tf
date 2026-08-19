resource "aws_iam_role" "axon_server" {
  name               = "${local.prefix}-server"
  assume_role_policy = data.aws_iam_policy_document.assume_axon_server.json
  tags               = merge(local.tags, { "Name" = "${local.prefix}-server" })
}

resource "aws_iam_role_policy_attachment" "axon_server_cloudwatch_logs_read" {
  role       = aws_iam_role.axon_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}
