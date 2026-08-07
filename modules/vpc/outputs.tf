output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.app_framework.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.app_framework.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.app_framework.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.app_framework_private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.app_framework_private[*].cidr_block
}

output "private_subnet_id" {
  description = "ID of the private subnet in AZ0, subnet index 1 (formerly private_ext)"
  value       = aws_subnet.app_framework_private[0].id
}

output "private_subnet_id_ext" {
  description = "ID of the private subnet in AZ0, subnet index 1 (formerly private_ext)"
  value       = aws_subnet.app_framework_private[1].id
}

output "private_subnets_by_az" {
  description = "Map of availability zone to list of private subnet IDs in that zone"
  value = {
    for az_index in range(local.az_count) :
    data.aws_availability_zones.available.names[az_index] =>
    [
      aws_subnet.app_framework_private[az_index * 2].id,
      aws_subnet.app_framework_private[az_index * 2 + 1].id
    ]
  }
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.app_framework_public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.app_framework_public.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.app_framework.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.app_framework.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.app_framework_public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.app_framework_private.id
}

