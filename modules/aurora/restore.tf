resource "aws_rds_cluster" "aurora_restore" {
  for_each = var.restore_to_point_in_time != null && (
    length(try(var.restore_to_point_in_time.source_cluster_identifiers, {})) == 0 ||
    contains(keys(try(var.restore_to_point_in_time.source_cluster_identifiers, {})), var.region)
  ) ? { restore = true } : {}

  cluster_identifier = "${local.prefix}-cluster-restored"
  region             = var.region
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.postgresql_version
  master_username    = var.master_username

  # Let AWS manage the master password
  manage_master_user_password = var.aws_managed_password

  # Enable IAM Database Authentication
  iam_database_authentication_enabled = var.iam_authentication_enabled

  # Point-in-time recovery configuration
  restore_to_point_in_time {
    source_cluster_identifier  = try(var.restore_to_point_in_time.source_cluster_identifiers[var.region], aws_rds_cluster.aurora.id)
    restore_type               = var.restore_to_point_in_time.restore_type
    restore_to_time            = var.restore_to_point_in_time.restore_to_time
    use_latest_restorable_time = var.restore_to_point_in_time.use_latest_restorable_time == true ? true : null
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

  tags = merge(local.tags, { "Name" = "${local.prefix}-cluster-restored" })

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }
}

# Aurora Serverless v2 Instance
resource "aws_rds_cluster_instance" "aurora_restored" {
  for_each = var.restore_to_point_in_time != null && (
    length(try(var.restore_to_point_in_time.source_cluster_identifiers, {})) == 0 ||
    contains(keys(try(var.restore_to_point_in_time.source_cluster_identifiers, {})), var.region)
  ) ? { restore = true } : {}

  region             = var.region
  identifier         = "${local.prefix}-instance-restored"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  # Performance Insights is configured at cluster level, but needs to be enabled on instances too
  performance_insights_enabled          = local.performance_insights_enabled
  performance_insights_retention_period = local.performance_insights_retention_period

  # Make instance publicly accessible (or not)
  publicly_accessible = false

  tags = merge(local.tags, { "Name" = "${local.prefix}-instance-restored" })
}
