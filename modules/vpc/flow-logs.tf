locals {
  # if no vpc_flow_log_name is provided, default to the bucket name
  vpc_flow_log_name = var.vpc_flow_log_name != null && var.vpc_flow_log_name != "" ? var.vpc_flow_log_name : var.vpc_flow_logs_bucket_name

  # merge primary bucket name with additional bucket names for backwards compatibility
  # Only include primary bucket if it's not null/empty
  vpc_flow_logs_bucket_names = compact(concat(
    [var.vpc_flow_logs_bucket_name],
    var.additional_vpc_flow_logs_bucket_names
  ))

  # merge the vpc flowlog name with additional flow log names, one for each bucket.
  flow_log_names = compact(concat(
    [local.vpc_flow_log_name],
    var.additional_vpc_flow_logs_bucket_names
  ))
}

# --- resources ---

resource "aws_flow_log" "default" {
  count                    = length(local.vpc_flow_logs_bucket_names)
  region                   = var.region
  log_destination          = "arn:aws:s3:::${local.vpc_flow_logs_bucket_names[count.index]}"
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.app_framework.id
  max_aggregation_interval = 600

  # Conditionally apply enhanced log format with all available fields if this bucket is specified
  # When vpc_flow_logs_enhanced_format_bucket_name is empty, all flow logs use the default format
  # https://docs.aws.amazon.com/vpc/latest/userguide/flow-log-records.html#flow-logs-fields
  log_format = (
    contains(var.vpc_flow_logs_enhanced_format_bucket_name, local.vpc_flow_logs_bucket_names[count.index])
    ? "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
    : null
  )

  tags = merge(local.tags, { "Name" = local.flow_log_names[count.index] })
}
