resource "aws_vpc" "app_framework" {
  region               = var.region
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.tags, { "Name" = "${local.prefix}-appinstance" })

  lifecycle {
    precondition {
      condition     = var.vpc_flow_logs_bucket_name != null
      error_message = "vpc_flow_logs_bucket_name must be provided when create_app_framework_vpc_flow_logs is true."
    }
  }
}

resource "aws_subnet" "app_framework_private" {
  count             = length(local.private_subnet_cidrs)
  region            = var.region
  availability_zone = data.aws_availability_zones.available.names[floor(count.index / 2)]
  cidr_block        = local.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.app_framework.id
  tags              = merge(local.tags, { "Name" = "${local.prefix}-appinstance-private-az${floor(count.index / 2)}-${count.index % 2}" })
}

resource "aws_subnet" "app_framework_public" {
  region            = var.region
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.app_framework.id
  tags              = merge(local.tags, { "Name" = "${local.prefix}-appinstance-public" })
}

# create internet gateway resource for analysis plane vpc
resource "aws_internet_gateway" "app_framework" {
  region = var.region
  vpc_id = aws_vpc.app_framework.id
  tags   = merge(local.tags, { "Name" = "${local.prefix}-appinstance-igw" })
}

# route table for public subnet, with route to internet gateway
resource "aws_route_table" "app_framework_public" {
  region = var.region
  vpc_id = aws_vpc.app_framework.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_framework.id
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-appinstance-public" })
}

resource "aws_route_table_association" "app_framework_public" {
  region         = var.region
  subnet_id      = aws_subnet.app_framework_public.id
  route_table_id = aws_route_table.app_framework_public.id
}

# regional nat gteway with automatic mode (AWS manages IPs and AZ expansion)
resource "aws_nat_gateway" "app_framework" {
  region            = var.region
  vpc_id            = aws_vpc.app_framework.id
  connectivity_type = "public"   # Required for regional NAT
  availability_mode = "regional" # Regional NAT with automatic multi-AZ HA

  # Automatic mode - AWS manages IP addresses and AZ expansion
  # No subnet_id, allocation_id, or ip_configuration needed

  tags = merge(local.tags, { "Name" = "${local.prefix}-appinstance-nat-gw" })

  depends_on = [aws_internet_gateway.app_framework]
}

# route all outbound traffic from the private VPC subnet through the NAT gateway
resource "aws_route_table" "app_framework_private" {
  region = var.region
  vpc_id = aws_vpc.app_framework.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_framework.id
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-appinstance-private" })
}

resource "aws_route_table_association" "app_framework_private" {
  region         = var.region
  count          = length(local.private_subnet_cidrs)
  subnet_id      = aws_subnet.app_framework_private[count.index].id
  route_table_id = aws_route_table.app_framework_private.id
}
