# workbench resource and principal tags used in workspace manager

locals {
  principal_tags = {
    bucket_id           = "S3BucketID"
    workbench_bucket_id = "TerraBucketID"
    user_id             = "UserID"
    ws_role             = "WorkspaceRole"
    version             = "Version"
    workspace_id        = "WorkspaceId"
    resource_id         = "ResourceId"
    session_type        = "SessionType"

    external_bucket_id      = "ExternalBucketID"
    external_bucket_prefix  = "ExternalBucketPrefix"
    external_bucket_account = "ExternalBucketAccount"

    external_repository_name    = "ExternalRepositoryName"
    external_repository_account = "ExternalRepositoryAccount"
    external_repository_region  = "ExternalRepositoryRegion"

    database_cluster = "DatabaseCluster"
    database_name    = "DatabaseName"
    database_access  = "DatabaseAccess"
  }

  resource_tags = {
    user_id      = "UserID"
    version      = "Version"
    tenant       = "Tenant"
    environment  = "Environment"
    workspace_id = "WorkspaceId"
    resource_id  = "ResourceId"
    account_name = "Account"
    aurora       = "WorkbenchManagedAurora"
    efs          = "WorkbenchManagedEFS"
  }

  # --- tags
  # default tags applied to all resources.
  tags = merge(
    var.tags,
    {
      AccountID                          = local.account_id
      DeploymentID                       = var.deployment_id
      WorkbenchDiscovery                 = "true"
      ManagedBy                          = "Terraform"
      (local.resource_tags.version)      = local.major_version
      (local.resource_tags.account_name) = var.account_name
      (local.resource_tags.tenant)       = var.tenant
      (local.resource_tags.environment)  = var.environment
  })

  # --- workflow tags
  # tags used for all workflow service resources.
  workflow_tags = merge(local.tags, {
    WorkbenchPrincipal = "WorkflowManagerService"
  })
}
