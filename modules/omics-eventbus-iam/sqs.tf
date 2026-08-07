resource "aws_sqs_queue" "omics_events" {
  name                        = local.omics_events_sqs_queue_name
  fifo_queue                  = true
  content_based_deduplication = true

  tags = merge(local.tags, { "Name" = local.omics_events_sqs_queue_name })
}

resource "aws_iam_policy" "process_sqs_workflow_messages" {
  name   = "${var.prefix}-process-workflow-messages"
  policy = data.aws_iam_policy_document.process_sqs_workflow_messages.json
  tags   = merge(local.tags, { "Name" = "${var.prefix}-process-workflow-messages" })
}

resource "aws_sqs_queue_policy" "sqs_write_omics_events" {
  queue_url = aws_sqs_queue.omics_events.url
  policy    = data.aws_iam_policy_document.sqs_write_omics_events.json
}

resource "aws_iam_role_policy_attachment" "process_sqs_workflow_messages" {
  role       = var.workflow_manager_role_name
  policy_arn = aws_iam_policy.process_sqs_workflow_messages.arn
}

# --- policy documents ---

data "aws_iam_policy_document" "process_sqs_workflow_messages" {
  statement {
    sid = "${var.sid_prefix}SQSProcessMessages"

    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = [local.omics_sqs_resource]
  }
}


data "aws_iam_policy_document" "sqs_write_omics_events" {
  statement {
    sid = "${var.sid_prefix}EventBridgeSQSWrite"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [aws_sqs_queue.omics_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.omics_state_changes.arn]
    }
  }
}
