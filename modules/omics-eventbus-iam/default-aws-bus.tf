# This file defines the IAM role and policies to allow access to the
# AWS-created default event bus.

resource "aws_iam_role" "omics_events_bus_invoke" {
  name               = "${var.prefix}-bus-invoker"
  assume_role_policy = data.aws_iam_policy_document.omics_events_bus_invoke.json
  tags               = merge(local.tags, { "Name" = "${var.prefix}-bus-invoker" })
}

resource "aws_iam_role_policy" "events_omics_bus_write" {
  name   = "${var.prefix}-bus-invoker"
  role   = aws_iam_role.omics_events_bus_invoke.name
  policy = data.aws_iam_policy_document.events_omics_bus_write.json
}

# --- policy documents ---

data "aws_iam_policy_document" "omics_events_bus_invoke" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

data "aws_iam_policy_document" "events_omics_bus_write" {
  statement {
    sid = "${var.sid_prefix}OmicsEventBusWrite"

    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [aws_cloudwatch_event_bus.omics_events.arn]
  }
}
