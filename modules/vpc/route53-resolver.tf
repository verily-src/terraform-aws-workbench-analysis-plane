# --- route 53 resolver query logging
# sends DNS query logs to S3

resource "aws_route53_resolver_query_log_config" "app_framework_s3" {
  count           = local.dns_log_count
  region          = var.region
  name            = "${local.prefix}-dns-query-logging-s3"
  destination_arn = "arn:aws:s3:::${var.vpc_dns_log_bucket}"
}

resource "aws_route53_resolver_query_log_config_association" "app_framework_s3" {
  count                        = local.dns_log_count
  region                       = var.region
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.app_framework_s3[0].id
  resource_id                  = aws_vpc.app_framework.id
}
