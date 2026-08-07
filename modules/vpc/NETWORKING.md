# Networking

This document describes the networking configuration for the application framework, as defined in `app_framework.tf`.

The setup includes a Virtual Private Cloud (VPC) with multi-AZ deployment across all available availability zones in the region. Each AZ contains public, private, and private extension subnets. This architecture provides high availability and fault tolerance while maintaining secure isolation of resources and necessary outbound internet access.

## VPC

A single VPC is created to house all the application framework resources.

- **CIDR Block:** `10.0.0.0/16`

## Subnets and Routing

The VPC is divided into subnets distributed across all available availability zones (AZs) in the region. Each subnet type is replicated per AZ, providing high availability and fault tolerance. The following table describes the subnet allocation strategy:

### Multi-AZ Subnet Allocation

| Subnet Type       | AZ0 CIDR Block   | AZ1+ CIDR Pattern      | IPs per AZ | Count per AZ | Status   | Notes                                                                                                         |
|-------------------|------------------|------------------------|------------|--------------|----------|---------------------------------------------------------------------------------------------------------------|
| **Private**       | `10.0.1.0/24`    | `10.0.7.0/26`, `/26...` (from `10.0.7.0/22`) | 256 (AZ0), 64 (AZ1+) | 1 per AZ | Occupied | Application EC2 instances. No direct internet ingress. Egress routed through Regional NAT Gateway. |
| **Public**        | `10.0.2.0/24`    | N/A | 256 | AZ0 only | Occupied | Routes to/from internet via Internet Gateway. Single AZ deployment. |
| **Private Extension** | `10.0.192.0/18` | `10.0.16.0/20`, `/20...` | 16,384 (AZ0), 4,096 (AZ1+) | 1 per AZ | Occupied | Large-scale application workloads (ECS, EC2 fleets). Egress via Regional NAT Gateway. |
| **Aurora Private AZ1** | `10.0.188.0/23` | N/A | 512 | Fixed | Occupied | Dedicated subnet for Aurora Serverless cluster in AZ0. Isolated (no route table). |
| **Aurora Private AZ2** | `10.0.190.0/23` | N/A | 512 | Fixed | Occupied | Dedicated subnet for Aurora Serverless cluster in AZ1. Isolated (no route table). |

### Backward Compatibility

- **AZ0 (first availability zone)** retains the original CIDR blocks for backward compatibility
- **AZ1+** use dynamically calculated CIDR blocks from allocated space (`10.0.7.0/22` for private subnets)
- Public subnets exist only in AZ0 for cost optimization (single Internet Gateway)
- Supports up to 16 availability zones before exhausting allocated address space

### Remaining Free Space

| CIDR Block                     | IP Range                      | Count  | Status   |
|--------------------------------|-------------------------------|--------|----------|
| `10.0.0.0/24`                  | `10.0.0.0` - `10.0.0.255`     | 256    | **Free** |
| `10.0.3.0` - `10.0.6.255`      | `10.0.3.0` - `10.0.6.255`     | 1,024  | **Free** |
| `10.0.11.0` - `10.0.15.255`    | `10.0.11.0` - `10.0.15.255`   | 1,280  | **Free** |
| `10.0.64.0` - `10.0.187.255`   | `10.0.64.0` - `10.0.187.255`  | ~31,744| **Free** |

**Note:** `10.0.7.0/22` is allocated for multi-AZ private subnet expansion.

### Gateways

- **Internet Gateway:** Provides a target in the VPC route tables for internet-routable traffic. The public subnet in AZ0 has a dedicated route table that routes to the Internet Gateway.
- **Regional NAT Gateway:** A single regional NAT gateway with automatic mode provides internet access for all private subnets across all AZs. AWS automatically manages IP addresses and expands the NAT gateway to AZs with active workloads (up to 60 minutes expansion time). This provides automatic failover and high availability without manual per-AZ NAT gateway management.

## VPC Endpoints

To improve security and reduce NAT gateway data processing costs, several VPC endpoints are configured. These endpoints allow resources within the VPC to communicate with AWS services privately, without traffic leaving the AWS network.

### S3 Gateway Endpoint

A Gateway VPC endpoint is configured for Amazon S3.

- **Type:** Gateway
- **Service:** S3
- **Function:** This endpoint adds a route to the private route table (`app_framework_private`). Any traffic from the private subnets (`Private` and `Private Extension`) destined for S3 within the same AWS region is automatically routed through this endpoint instead of the NAT Gateway. As this is a free resource that reduces costs, it is enabled by default via the `create_app_framework_s3_endpoint` variable.

### ECR Interface Endpoints

Two Interface VPC endpoints are configured for Amazon Elastic Container Registry (ECR) to facilitate private and cost-effective container image management.

- **Type:** Interface
- **Services:**
    - `com.amazonaws.<region>.ecr.api`: For ECR API calls.
    - `com.amazonaws.<region>.ecr.dkr`: For Docker client push/pull operations.
- **Deployment:** Endpoints are created only in AZ0's private extension subnet for cost optimization (~$365/year savings vs. per-AZ endpoints).
- **Function:** These endpoints create network interfaces with private IP addresses. With private DNS enabled, any DNS query for the ECR service from within the entire VPC resolves to these private IPs, making the endpoints accessible from all AZs. This ensures that all ECR traffic from any subnet is routed privately, avoiding the NAT Gateway. Because these endpoints incur an hourly cost (~$7.20/month each), they are disabled by default and can be enabled via the `create_app_framework_ecr_endpoints` variable.

## VPC Flow Logs

VPC Flow Logs are configured to capture information about the IP traffic going to and from network interfaces in the VPC. These logs are delivered to an S3 bucket for analysis and monitoring, as specified by the `vpc_flow_logs_bucket_name` variable.
