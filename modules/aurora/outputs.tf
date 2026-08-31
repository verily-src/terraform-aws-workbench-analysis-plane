output "aurora_clusters" {
  value = length(var.clusters) > 0 ? {
    for cluster in aws_rds_cluster.aurora :
    (cluster.id) => {
      # Connection endpoints
      writer_endpoint = cluster.endpoint
      reader_endpoint = cluster.reader_endpoint
      port            = cluster.port

      # Authentication
      master_username            = cluster.master_username
      master_password_secret_arn = cluster.master_user_secret[0].secret_arn

      # Resource identifiers
      cluster_arn         = cluster.arn
      cluster_resource_id = cluster.cluster_resource_id

      # Engine info
      engine         = cluster.engine
      engine_version = cluster.engine_version
    }
  } : { null = null }
  description = "WARNING: this output is used by discovery. Do not change the structure"
}
