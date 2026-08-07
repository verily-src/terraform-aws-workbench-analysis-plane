resource "aws_cloudwatch_event_rule" "omics_state_changes" {
  region      = var.region
  name        = "${local.prefix}-state-events"
  description = "Capture all Omics Task and Run status events."

  event_pattern = jsonencode({
    account = [var.account_id]
    source  = ["aws.omics"]

    detail-type = [
      "Task Status Change",
      "Run Status Change",
      "RunBatch Status Change"
    ]
  })

  tags = merge(local.tags, { "Name" = "${var.prefix}-state-events" })
}

resource "aws_cloudwatch_event_target" "omics_event_bus" {
  region    = var.region
  target_id = "send-to-omics-eventbus"
  arn       = var.events_bus_arn
  role_arn  = var.bus_invoke_role_arn
  rule      = aws_cloudwatch_event_rule.omics_state_changes.name
}
