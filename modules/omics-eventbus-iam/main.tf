# event bus that all workbench regions will forward omics events to.
resource "aws_cloudwatch_event_bus" "omics_events" {
  name = local.eventbridge_resource_name
  tags = merge(local.tags, { "Name" = "${var.prefix}-omics-events" })
}

# event rule that will catch all omics events in the omics event bus.
resource "aws_cloudwatch_event_rule" "omics_state_changes" {
  name           = local.eventbridge_resource_name
  description    = "Forward all Omics Task and Run status events."
  event_bus_name = aws_cloudwatch_event_bus.omics_events.name

  event_pattern = jsonencode({
    account = [var.account_id]
    source  = ["aws.omics"]

    detail-type = [
      "Task Status Change",
      "Run Status Change",
      "RunBatch Status Change"
    ]
  })

  tags = merge(local.tags, { "Name" = "${var.prefix}-omics-state-changes" })
}

resource "aws_cloudwatch_event_target" "omics_sqs" {
  target_id      = "SendToSQS"
  rule           = aws_cloudwatch_event_rule.omics_state_changes.name
  event_bus_name = aws_cloudwatch_event_bus.omics_events.name

  arn = aws_sqs_queue.omics_events.arn
  sqs_target {
    message_group_id = "omics-state-events"
  }
}
