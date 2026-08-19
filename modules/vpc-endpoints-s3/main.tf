# Creates a Gateway VPC endpoint for S3. This works by adding a route to the specified
# route table (`app_framework_private`). Since both the `app_framework_private` and
# `app_framework_private_ext` subnets are associated with this route table, any
# resources within them can access S3 privately without transiting the NAT gateway,
# which reduces cost.

resource "aws_vpc_endpoint" "s3" {
  region            = var.region
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.route_table_id]
  tags              = merge(local.tags, { "Name" = "${local.prefix}-appinstance" })
}
