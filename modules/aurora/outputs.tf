# WARNING: this output is used by discovery. Do not change the structure
output "clusters" {
  value = {
    (aws_rds_cluster.aurora.id) = {
      # resource identifiers
      cluster_arn         = aws_rds_cluster.aurora.arn
      cluster_resource_id = aws_rds_cluster.aurora.cluster_resource_id

      # engine info
      engine         = aws_rds_cluster.aurora.engine
      engine_version = aws_rds_cluster.aurora.engine_version

      # connection endpoints
      writer_endpoint = aws_rds_cluster.aurora.endpoint
      reader_endpoint = aws_rds_cluster.aurora.reader_endpoint
      port            = aws_rds_cluster.aurora.port

      # authentication
      master_username            = aws_rds_cluster.aurora.master_username
      master_password_secret_arn = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
    }
  }
  description = "WARNING: this output is used by discovery. Do not change the structure"
}
