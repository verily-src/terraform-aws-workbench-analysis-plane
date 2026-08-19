resource "aws_security_group" "aurora" {
  region = var.region
  name   = "${local.prefix}-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow PostgreSQL traffic from App Framework private subnets (all AZs)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.vpc_private_subnet_cidrs
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-sg" })
}

resource "aws_subnet" "aurora_subnets" {
  count             = length(local.aurora_availability_zone_cidrs)
  region            = var.region
  vpc_id            = var.vpc_id
  cidr_block        = local.aurora_availability_zone_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.tags, { "Name" = "${local.prefix}-private-az${count.index + 1}" })
}

resource "aws_db_subnet_group" "aurora" {
  region     = var.region
  name       = "${local.prefix}-subnet-group"
  subnet_ids = aws_subnet.aurora_subnets[*].id
  tags       = merge(local.tags, { "Name" = "${local.prefix}-subnet-group" })
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  region      = var.region
  name        = "${local.prefix}-parametergroup"
  family      = local.aurora_pg_family
  description = "Aurora PostgreSQL parameter group with pgAudit enabled for ${var.region}"

  # Enable pgAudit extension
  parameter {
    name         = "shared_preload_libraries"
    value        = "pgaudit"
    apply_method = "pending-reboot"
  }

  # Configure pgAudit to log DDL, write operations (INSERT/UPDATE/DELETE), and role changes
  parameter {
    name         = "pgaudit.log"
    value        = "all"
    apply_method = "immediate"
  }

  # Enable object auditing through rds_pgaudit role
  parameter {
    name         = "pgaudit.role"
    value        = "rds_pgaudit"
    apply_method = "immediate"
  }

  tags = merge(local.tags, { "Name" = "${local.prefix}-parametergroup" })
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.prefix}-cluster"
  region             = var.region
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.postgresql_version
  master_username    = var.master_username

  # Let AWS manage the master password
  manage_master_user_password = var.aws_managed_password

  # Enable IAM Database Authentication
  iam_database_authentication_enabled = var.iam_authentication_enabled

  # MIGRATION ONLY! Use the config in restore_to_point_in_time and restore.tf for disaster recovery.
  # This is used to migrate existing environments to new AP module usage
  dynamic "restore_to_point_in_time" {
    for_each = var.migrate_from_cluster != null ? [var.migrate_from_cluster] : []
    content {
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifiers[var.region]
      restore_type               = restore_to_point_in_time.value.restore_type
      restore_to_time            = restore_to_point_in_time.value.restore_to_time
      use_latest_restorable_time = restore_to_point_in_time.value.use_latest_restorable_time == true ? true : null
    }
  }

  # Enable RDS Data API
  enable_http_endpoint = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.aurora.id
  vpc_security_group_ids = [aws_security_group.aurora.id]

  # Attach parameter group with pgAudit configuration
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  serverlessv2_scaling_configuration {
    min_capacity             = var.min_acu
    max_capacity             = var.max_acu
    seconds_until_auto_pause = local.auto_pause_seconds
  }

  # Metrics and Logging
  database_insights_mode                = "advanced"
  performance_insights_enabled          = local.performance_insights_enabled
  performance_insights_retention_period = local.performance_insights_retention_period

  # Export PostgreSQL logs to CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Backup and maintenance
  backup_retention_period      = var.backup_retention_period_days
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # Cluster deletion settings
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.final_snapshot_identifier == null ? true : false
  final_snapshot_identifier = var.final_snapshot_identifier

  tags = merge(local.tags, { "Name" = "${local.prefix}-cluster" })

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }
}

# Aurora Serverless v2 Instance
resource "aws_rds_cluster_instance" "aurora" {
  region             = var.region
  identifier         = "${local.prefix}-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  # Performance Insights is configured at cluster level, but needs to be enabled on instances too
  performance_insights_enabled          = local.performance_insights_enabled
  performance_insights_retention_period = local.performance_insights_retention_period

  # Make instance publicly accessible (or not)
  publicly_accessible = false

  tags = merge(local.tags, { "Name" = "${local.prefix}-instance" })
}
