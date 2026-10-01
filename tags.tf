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

  # --- default tags
  # default tags applied to all resources.
  tags = merge(
    var.tags,
    {
      AccountID                          = local.account_id
      DeploymentID                       = var.deployment_id
      ManagedBy                          = "Terraform"
      (local.resource_tags.version)      = local.major_version
      (local.resource_tags.account_name) = var.account_name
      (local.resource_tags.tenant)       = var.tenant
      (local.resource_tags.environment)  = var.environment
  })

  # --- s3 object tags
  # S3 object tags have to be limited. AWS does not allow more than 10 tags.
  # Therefore, only include essential tags here to allow customer tags to be injected."
  s3_object_tags = {
    AccountID                          = local.account_id
    (local.resource_tags.version)      = local.major_version
    (local.resource_tags.account_name) = var.account_name
    (local.resource_tags.environment)  = var.environment
    (local.resource_tags.tenant)       = var.tenant
  }

  # --- workflow tags
  # tags used for all workflow service resources.
  workflow_tags = merge(local.tags, {
    WorkbenchPrincipal = "WorkflowManagerService"
  })
}
