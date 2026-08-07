locals {
  # --- name prefix
  # name prefix for all resources in this module, to ensure consistent naming 
  # across all resources and to make it easier to identify which resources 
  # belong to this module
  prefix = lower("${var.prefix}-omics")

  eventbridge_resource_name   = "${local.prefix}-all-state-events"
  omics_events_sqs_queue_name = "${local.prefix}-state-events-sqs.fifo"
  omics_sqs_resource          = "arn:aws:sqs:*:${var.account_id}:${local.omics_events_sqs_queue_name}"

  tags = merge(
    var.tags,
    {}
  )
}
