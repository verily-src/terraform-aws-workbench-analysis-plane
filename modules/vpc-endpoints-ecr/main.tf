# Security group for the VPC endpoints. It allows HTTPS traffic from within the VPC
# to the endpoints, which is required for the ECR interface endpoints to function.
resource "aws_security_group" "ecr_vpc_endpoints" {
  region = var.region
  name   = "${local.prefix}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-sg" })
}

# Creates an Interface VPC endpoint for the ECR API. This places a network interface
# in the private subnet for AZ0 (subnet index 1, which was the former private_ext subnet).
# Private DNS is enabled to automatically resolve the ECR API hostname for the entire VPC,
# allowing resources in all AZs to access it.
resource "aws_vpc_endpoint" "ecr_api" {
  region              = var.region
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [var.subnet_id] # AZ0, subnet 1 (formerly private_ext)
  security_group_ids  = [aws_security_group.ecr_vpc_endpoints.id]
  tags                = merge(local.tags, { "Name" = "${local.prefix}-api-appinstance" })
}

# Creates an Interface VPC endpoint for the ECR Docker registry. This places a network
# interface in the private subnet for AZ0 (subnet index 1, which was the former private_ext subnet).
# Private DNS is enabled for seamless resolution for the entire VPC, allowing resources in all AZs to access it.
resource "aws_vpc_endpoint" "ecr_dkr" {
  region              = var.region
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [var.subnet_id] # AZ0, subnet 1 (formerly private_ext)
  security_group_ids  = [aws_security_group.ecr_vpc_endpoints.id]
  tags                = merge(local.tags, { "Name" = "${local.prefix}-dkr-appinstance" })
}
